open Sexp
open Errors
open Parser
open Prelude
open Checker
open Datatypes

let st : state ref = ref
  { variables = Names.empty;
    infix     = Env.empty;
    context   = Env.empty;
    bound     = [];
    defs      = [] }

let upTerm ctx name tau =
  Env.add name { premises = []; conclusion = freeze tau } ctx

let upDecl st name decl =
  if Env.mem name !st.context then
    raise (AlreadyDefinedError name)
  else st := { !st with context = Env.add name decl !st.context }

let infix op prec =
  st := { !st with infix = Env.add op prec !st.infix }

let variables xs =
  st := { !st with variables = Names.union !st.variables (Names.of_list xs) }

let constants xs =
  st := { !st with variables = Names.diff  !st.variables (Names.of_list xs) }

let parse expr = Parser.parse !st expr
let run func elab default filename =
  getSExp filename
  |> func (handle (extList >> parse >> elab) default)

let rec elab : command -> unit = function
  | Infix (op, prec) -> infix op prec
  | Variables xs -> variables xs
  | Constants xs -> constants xs
  | Bound xs ->
    st := { !st with bound = !st.bound @ xs }
  | Macro (pattern, body, _) ->
    let fv : sub ref = ref Sub.empty in
    iterVars (fun name ->
      if not (occurs name pattern || Sub.mem name !fv) then begin
        (* New name contains space so it cannot be used by user *)
        let sym = gensym () |> Printf.sprintf "«? %s»" in
        fv := Sub.add name (Var (sym, snd name)) !fv
      end) body;

    st := { !st with defs = (pattern, multisubst !fv body) :: !st.defs }
  | Include xs -> List.iter dofile xs
  | Macroexpand xs ->
    List.iter (fun (x, y) ->
      Printf.printf "%s expands to %s\n" (showSExp x) (showTerm y)) xs
  | Axiom xs ->
    List.iter (fun (name, rule) ->
      upDecl st name rule;
      Printf.printf "“%s” postulated\n" name) xs
  | Decl { name; hypothesises; rule; proof } ->
    let ctx = List.fold_left2 upTerm !st.context hypothesises rule.premises in
    begin try
      check ctx !st.bound (freeze rule.conclusion) proof;
      upDecl st name rule; Printf.printf "“%s” declared\n" name
    with ex ->
      Printf.printf "“%s” has not been declared\n" name;
      prettyPrintError ex
    end
  | Description xs -> ()
and dofile filename =
  Printf.printf "Parsing “%s”.\n" filename;
  run List.iter elab () filename