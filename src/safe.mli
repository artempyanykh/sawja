
module Domain : sig

  (** This may be used to combine analysis. *)
  module type TRADUCTOR_ANALYSIS =
  sig
    type localID
    type localDomain
    type globalID
    type globalDomain
    val loc2gloID : localID -> globalID
    val loc2gloDomain : localDomain -> globalDomain
    val glo2locID : globalID -> localID
    val glo2locDomain : globalDomain -> localDomain
  end

  (** Used when there is only one analysis. *)
  module Trad_Identity :
    functor (TYPE : sig type id type dom end) ->
  sig
    type localID = TYPE.id
    type localDomain = TYPE.dom
    type globalID = TYPE.id
    type globalDomain = TYPE.dom
    val loc2gloID : localID -> globalID
    val loc2gloDomain : localDomain -> globalDomain
    val glo2locID : globalID -> localID
    val glo2locDomain : globalDomain -> localDomain
  end

  module type S = sig

    (** Type of combined sub-analysis domains (eg. D1.t * D2.t). *)
    type t

    (** Type of combined sub-analyses IDs (Left of D1.analysisID | Right of
        D2.analysisID)*)
    type analysisID

    (** Type of sub-analysis domains (eg. Left of D1.analysisDomain | Right of
        D2.analysisDomain) *)
    type analysisDomain

    (** Standard domain operations. *)

    val bot : t
    val isBot : analysisDomain -> bool

    (** [join modifies v1 v2] returns the union of [v1] and [v2] and sets
        [modifies] to true iff the result is different from [v1]. *)
    val join : ?modifies:bool ref -> t -> t -> t
    val join_ad : ?modifies:bool ref -> t -> analysisDomain -> t
    val equal : t -> t -> bool
    val get_analysis : analysisID -> t -> analysisDomain
    val pprint : Format.formatter -> t -> unit
  end

  module Empty : S
    
  (** Builds a domain for local variables given the domain of the variables.  *)
  module Local : functor (Var:S) -> sig
    type t
    type analysisID = Var.analysisID
    type analysisDomain = t
    val bot : t
    val isBot : analysisDomain -> bool
    val join : ?modifies:bool ref -> t -> t -> t
    val join_ad : ?modifies:bool ref -> t -> analysisDomain -> t
    val equal : t -> t -> bool
    val get_analysis : analysisID -> t -> analysisDomain
    val pprint : Format.formatter -> t -> unit
    val get_var : int -> analysisDomain -> Var.t
    val set_var : int -> Var.t -> analysisDomain -> analysisDomain
  end

  module Stack : functor (Var:S) -> sig
    type t
    type analysisID = Var.analysisID
    type analysisDomain = t
    val bot : t
    val isBot : analysisDomain -> bool
    val join : ?modifies:bool ref -> t -> t -> t
    val join_ad : ?modifies:bool ref -> t -> analysisDomain -> t
    val equal : t -> t -> bool
    val get_analysis : analysisID -> t -> analysisDomain
    val pprint : Format.formatter -> t -> unit
    val init : t
      (** initial (empty) stack *)
    val push : Var.t -> t -> t
    val pop_n : int -> t -> t
    val pop : t -> t
    val first : t -> Var.t
      (** raise [Invalid_argument] if the stack is empty. raise Failure if the
          stack is Top. *)
    val dup : t -> t
    val dupX1 : t -> t
    val dupX2 : t -> t
    val dup2 : t -> t
    val dup2X1 : t -> t
    val dup2X2 : t -> t
    val swap : t -> t
  end

  module Combine : functor (Left : S) -> functor (Right : S) -> sig
    include S
    module Trad_Left : functor (Trad : TRADUCTOR_ANALYSIS
                                with type globalID = Left.analysisID
                                and type globalDomain = Left.analysisDomain) ->
      (TRADUCTOR_ANALYSIS
       with type localID = Trad.localID
       and type localDomain = Trad.localDomain
       and type globalID = analysisID
       and type globalDomain = analysisDomain)
    module Trad_Right :
      functor (Trad : TRADUCTOR_ANALYSIS
               with type globalID = Right.analysisID
               and type globalDomain = Right.analysisDomain) ->
        (TRADUCTOR_ANALYSIS
         with type localID = Trad.localID
         and type localDomain = Trad.localDomain
         and type globalID = analysisID
         and type globalDomain = analysisDomain)
  end

end



module Var : sig

  module type CONTEXT =
  sig

  (** The Context could be
      - Context sensibility (duplicate program point)
      - Analysis identification (several pp because several analyses)
      - Flow information (Intermediate state, return, parameters,
         exception returned, etc. ) *)
    type context

    val compare : context -> context -> int
    val equal : context -> context -> bool
    val hash : context -> int
    val to_string : context -> string
    val pprint : Format.formatter -> context -> unit
  end
  module EmptyContext : (CONTEXT with type context = unit)

  module type S = sig
    module Context : CONTEXT

    (** just a shortcut *)
    type ioc = JBasics.class_name
    type var_global = [ `Global of Context.context ]
    type var_ioc = [ `IOC of Context.context * ioc ]
    type var_field =
        [ `Field of Context.context * ioc * JBasics.field_signature ]
    type var_method =
        [ `Method of Context.context * ioc * JBasics.method_signature ]
    type var_pp =
        [ `PP of Context.context * ioc * JBasics.method_signature * int ]
    type t =
        [ `Field of Context.context * ioc * JBasics.field_signature
        | `Global of Context.context
        | `IOC of Context.context * ioc
        | `Method of Context.context * ioc * JBasics.method_signature
        | `PP of Context.context * ioc * JBasics.method_signature * int ]
    val compare : t -> t -> int
    val equal : t -> t -> bool
    val hash : t -> int
    val pprint : Format.formatter -> t -> unit
    val compare_global : var_global -> var_global -> int
    val compare_ioc : var_ioc -> var_ioc -> int
    val compare_field : var_field -> var_field -> int
    val compare_method : var_method -> var_method -> int
    val compare_pp : var_pp -> var_pp -> int
    val equal_global : var_global -> var_global -> bool
    val equal_ioc : var_ioc -> var_ioc -> bool
    val equal_field : var_field -> var_field -> bool
    val equal_method : var_method -> var_method -> bool
    val equal_pp : var_pp -> var_pp -> bool
    val hash_global : var_global -> int
    val hash_ioc : var_ioc -> int
    val hash_field : var_field -> int
    val hash_method : var_method -> int
    val hash_pp : var_pp -> int
    val pprint_global : Format.formatter -> var_global -> unit
    val pprint_ioc : Format.formatter -> var_ioc -> unit
    val pprint_field : Format.formatter -> var_field -> unit
    val pprint_method : Format.formatter -> var_method -> unit
    val pprint_pp : Format.formatter -> var_pp -> unit
  end

  module Make :
    functor (Context : CONTEXT) -> (S with module Context = Context)
      
end

module State : sig

  module type S = sig

    (** One domain for each type of variable. *)
    module Var : Var.S
    module Global : Domain.S
    module IOC : Domain.S
    module Field : Domain.S
    module Method : Domain.S
    module PP : Domain.S

    type analysisID =
        [ `FieldAnalysis of Field.analysisID
        | `GlobalAnalysis of Global.analysisID
        | `IOCAnalysis of IOC.analysisID
        | `MethodAnalysis of Method.analysisID
        | `PPAnalysis of PP.analysisID ]

    (** Data (value) for one particular analysis. *)
    type analysisDomain =
        [ `FieldDomain of Field.analysisDomain
        | `GlobalDomain of Global.analysisDomain
        | `IOCDomain of IOC.analysisDomain
        | `MethodDomain of Method.analysisDomain
        | `PPDomain of PP.analysisDomain ]

    (** Data for all analyses for one particular variable (slot). *)
    type abData =
        [ `Field of Field.t
        | `Global of Global.t
        | `IOC of IOC.t
        | `Method of Method.t
        | `PP of PP.t ]

    type t
    val bot : unit -> t
    val pprint : Format.formatter -> t -> unit
    val get_pinfo :
      'a JProgram.program -> t -> JPrintHtml.info -> JPrintHtml.info

    val join : ?modifies:bool ref -> t -> Var.t -> analysisDomain -> unit
    val join_ad :
      ?modifies:bool ref -> abData -> analysisDomain -> abData

    val get : t -> Var.t -> abData
    val get_global : t -> Var.var_global -> Global.t
    val get_IOC : t -> Var.var_ioc -> IOC.t
    val get_field : t -> Var.var_field -> Field.t
    val get_method : t -> Var.var_method -> Method.t
    val get_PP : t -> Var.var_pp -> PP.t

    val get_ab_global : abData -> Global.t
    val get_ab_field : abData -> Field.t
    val get_ab_method : abData -> Method.t
    val get_ab_IOC : abData -> IOC.t
    val get_ab_pp : abData -> PP.t
  end

  module Make :
    functor (Var : Var.S) ->
      functor (GlobalDomain : Domain.S) ->
        functor (IOCDomain : Domain.S) ->
          functor (FieldDomain : Domain.S) ->
            functor (MethodDomain : Domain.S) ->
              functor (PPDomain : Domain.S) ->
                (S with module Var = Var
                   and module Global = GlobalDomain
                   and module IOC = IOCDomain
                   and module Field = FieldDomain
                   and module Method = MethodDomain
                   and module PP = PPDomain)
end


module Constraints : sig

  module type S = sig
    module State : State.S
    type variable = State.Var.t
    type cst = {
      dependencies : variable list;
      target : variable;
      transferFun : State.t -> State.analysisDomain;
    }
    val get_dependencies : cst -> variable list
    val get_target : cst -> variable
    val pprint : Format.formatter -> cst -> unit

    (** [apply_cst ?modifies abst cst] apply the constraint [cst] on the current
        [abst].  The result of the constraint (given by [cst.transferFun]) is
        joined to the current value stored in [abst].  [modifies] is set to true
        if the application of constraint modified the state [abst].*)
    val apply_cst : ?modifies:bool ref -> State.t -> cst -> unit
  end

  module Make : functor (State : State.S) ->
    (S with module State = State)
end

module Solver : sig
  module Make : functor (Constraints : Constraints.S) -> sig
    val debug_level : int ref
    val solve_constraints :
      'a ->
      Constraints.cst list ->
      Constraints.State.t ->
      Constraints.State.Var.t list -> Constraints.State.t
  end
end
