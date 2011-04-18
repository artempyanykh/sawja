(*
 * This file is part of SAWJA
 * Copyright (c)2007, 2008 Tiphaine Turpin (Université de Rennes 1)
 * Copyright (c)2007, 2008, 2009 Laurent Hubert (CNRS)
 * Copyright (c)2009 Nicolas Barre (INRIA)
 *
 * This program is free software: you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation, either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program.  If not, see
 * <http://www.gnu.org/licenses/>.
 *)


(* TODO: static_lookup_* function have been removed. this was a bad
   idea.*)

(** Provides some JVM resolution and lookup functions and allows some navigation in the control flow graph of a program for static analysis. *)


open Javalib_pack
open JBasics
open Javalib
open JProgram

(** {2 JVM resolution and lookup functions}*)

(** {3 Lookup and resolution procedures} *)

(** {b Warning : lookup and resolve functions do not take in account
    visibility yet}! *)


(** [resolve_class p cn] returns the class named [cn] in program [p], if
    any.
    @raise NoClassDefFoundError if [p] does not contain a class named
    [cn].
*)
val resolve_class : 'a program -> class_name -> 'a node

(** [resolve_method ms c] returns the class or interface that defines
    the method [ms], if any. If [c] does not define [ms], then [ms] is
    searched recursivly in superclasses and interfaces of [c]. The caller
    is responsible to check that the class and the method defined in
    the class are visible from the current class.  @raise
    NoSuchMethodError if the method is not found
*)
val resolve_method : method_signature -> 'a class_node -> 'a node

(** [resolve_method' ms c] only look for the method in [c] and its
    superclasses. *)
val resolve_method' : method_signature -> 'a class_node -> 'a class_node
  



(** [resolve_interface_method ms c] returns the interface that defines
    the method [ms], or [java.lang.Object] if no interface defines
    [ms] but [Object] does.  The caller is responsible to check that
    the interface and the method defined in the interface are visible
    from the current class.
    @raise NoSuchMethodError if the method is not found.
*)
val resolve_interface_method : method_signature -> 'a interface_node -> 'a node

(** [resolve_interface_method' ms c] looks for the methods [ms] in [c]
    interfaces and recursively in their super-interfaces, stopping at
    every first occurence in each hierarchy. It returns the list of
    interfaces that defines [ms]. *)
val resolve_interface_method' :
  ?acc:'a interface_node list -> method_signature -> 'a node -> 'a interface_node list




(** [resolve_field fsi c] returns the list of classes and interfaces
    that define the field [(c,fsi)], if any.  See the JVM Spec for the
    algorithm.  Several interfaces may define the same field and it is
    not specify which one to take (there is no order relation on
    direct interfaces), so this function returns a list.

    @see <http://java.sun.com/docs/books/jvms/second_edition/html/ConstantPool.doc.html#71685> Field Resolution
*)
val resolve_field : field_signature -> 'a node -> 'a node list

(*
(** [lookup_virtual_method ms c] returns the class that defines the
    method [ms], if any.  The caller is responsible to check that the
    class and the method defined in the class are visible from the
    current class.
    @raise AbstractMethodError if the method is not found or if the
    method is abstract.
*)
val lookup_virtual_method : method_signature -> 'a class_node -> 'a class_node

(** [lookup_interface_method ms c] returns the class that defines the
    method [ms], if any. The caller is responsible to check that the
    class returned is visible from the current class. As the method is
    supposed to have been declared in a interface (and
    [resolve_interface_method] can ensure that), the method is
    necessarily [public].
    @raise AbstractMethodError if the method is not found or if the
    method is abstract.
*)
val lookup_interface_method : method_signature -> 'a class_node -> 'a class_node
*)

(** [static_lookup_virtual p obj ms] returns the classes or interfaces
    that defines the method [ms], if any.  The caller is responsible
    to check that the class and the method defined in the class are
    visible from the current class.  @raise
    IncompatibleClassChangeError if the type [obj] is the type of an
    interface.*)
val static_lookup_virtual :
  'a program -> object_type -> method_signature -> 'a node list

(** [static_lookup_interface p cs ms] returns the classes or
    interfaces that defines the method [ms], if any.  The caller is
    responsible to check that the class and the method defined in the
    class are visible from the current class.  *)
val static_lookup_interface :
  'a program -> class_name -> method_signature -> 'a node list

(** [static_lookup_special program c cs ms] returns the defining class
    of the method that would be reached by executing "invokespecial
    cs.ms" with c as the current class. *)
val static_lookup_special :
  'a program -> 'a node -> class_name -> method_signature -> 'a class_node

(** [static_lookup_static p cs ms] returns the classe that defines the
    method [ms].  The caller is responsible to check that the class
    and the method defined in the class are visible from the current
    class.  *)
val static_lookup_static :
  'a program -> class_name -> method_signature -> 'a node

(** {3 Utility functions using lookup and resolution}*)

(** [implements_methods ms c] looks for the interfaces that defines
    method [ms] in the direct interfaces of [c] and recursively in
    their super-interfaces. If [i1] and [i2] defines [ms] and [i1]
    extends [i2], then [i1] is before [i2] in the result list.

    @raise Not_found if [ms] cannot be found in [c]
*)
val implements_methods : method_signature -> 'a class_node -> 'a interface_node list

(** [resolve_all_interface_methods ms i] returns the list of
    interfaces that defines the method [ms] looking for [ms] in [i]
    and then recursivly in its super-interfaces. If [i1] and [i2]
    defines [ms] and [i1] extends [i2], then [i1] is before [i2] in
    the result list. The caller is responsible to check that the
    interface and the method defined in the interface are visible from
    the current class.
*)
val resolve_all_interface_methods : method_signature -> 'a interface_node -> 'a interface_node list

(** [overrides_methods ms c] looks for the classes that define
    methods that are overridden by [(c,ms)] (in the parents of
    [c]). The result list is ordered such that [c1] is before [c2] iff
    [c1] extends [c2].

    @raise Not_found if [ms] cannot be found in [c]
*)
val overrides_methods : method_signature -> 'a class_node -> 'a class_node list

(** [overridden_by_methods ms c] looks for the classes that define
    methods that overrides (or implements) [(c,ms)] (in the children
    of [c]).

    @raise Invalid_argument("overridden_by_methods") if the method is
    a class or instance initialization method.*)
val overridden_by_methods : method_signature -> 'a node -> 'a class_node list

(** [implements_method c ms] returns [true] iff the class has a method
    with the signature [ms] and which is not abstract. (Note: The
    method can be native.)
*)
val implements_method : 'a class_node -> method_signature -> bool

(** [implements_interface_or_subinterface n i] looks if [n] or one of
    its interfaces transitively implements [i], it returns true if
    it is the case.*)
val implements_interface_or_subinterface : 'a node -> 'a interface_node
  -> bool

(** [implements_interface_or_subinterface_transitively n i] looks if
    [n] or one of its interfaces transitively implements [i], if it
    is not the case it does it looks transitively on superclasses of
    [n]. It returns true if [n] transitively implements [i].*)
val implements_interface_or_subinterface_transitively : 'a class_node ->
  'a interface_node -> bool


(** {2 Static Analysis functions}*)

(** {3 Access to instructions and navigation}*)

(** Manipulation of generic program pointers (should not be used when
    a specific code representation (JCode, JBir, etc.) is manipulated, use PP_* instead).*)
module PP : sig
  type 'a t
  exception NoCode of (class_name * method_signature)
  val get_class : 'a t -> 'a node
  val get_meth : 'a t -> 'a concrete_method
  val get_pc : 'a t -> int

  val get_pp : 'a node -> 'a concrete_method -> int -> 'a t

  (** [get_first_pp p cn ms] gets a pointer to the first instruction
      of the method [ms] of the class [cn].

      @raise Not_found if [cn] is not a class of [p], or [ms] is not a
      method of [cn].

      @raise NoCode if the method [ms] has no associated code.*)
  val get_first_pp : 'a program -> class_name -> method_signature -> 'a t
  val get_first_pp_wp : 'a node -> method_signature -> 'a t
  val goto_absolute : 'a t -> int -> 'a t
  val goto_relative : 'a t -> int -> 'a t

  val to_string : 'a t -> string
  val pprint : Format.formatter -> 'a t -> unit

  val equal : 'a t -> 'a t -> bool
  val compare : 'a t -> 'a t -> int
  val hash : 'a t -> int
end

(** Common signature (corresponding to {!PP}) included in PP_* modules *)
module type GenericPPSig = sig
  type code
  type t = code PP.t
  exception NoCode of (class_name * method_signature)
  val get_class : t -> code node
  val get_meth : t -> code concrete_method
  val get_pc : t -> int

  val get_pp : code node -> code concrete_method -> int -> t

  (** [get_first_pp p cn ms] gets a pointer to the first instruction
      of the method [ms] of the class [cn].

      @raise Not_found if [cn] is not a class of [p], or [ms] is not a
      method of [cn].

      @raise NoCode if the method [ms] has no associated code.*)
  val get_first_pp : code program -> class_name -> method_signature -> t
  val get_first_pp_wp : code node -> method_signature -> t
  val goto_absolute : t -> int -> t
  val goto_relative : t -> int -> t

  val to_string : t -> string
  val pprint : Format.formatter -> t -> unit

  val equal : t -> t -> bool
  val compare : t -> t -> int
  val hash : t -> int
end

(** Manipulation of {!Javalib_pack.JCode.jcode} program pointers *)
module PP_BC : sig
  (** [with type code =] {!Javalib_pack.JCode.jcode}*)
  include GenericPPSig with type code = JCode.jcode 

  val get_opcode : JCode.jcode PP.t -> JCode.jopcode

  (** returns the next instruction if there is one.  If there is
      not, the behavior is unspecified (specially if compiled with
      -unsafe...) *)
  val next_instruction : JCode.jcode PP.t -> JCode.jcode PP.t

  (** returns the normal intra-procedural successors of an
      instruction*)
  val normal_successors : JCode.jcode PP.t -> JCode.jcode PP.t list

  (** returns the handlers that could catch an exception thrown from
      the current instruction*)
  val handlers : JCode.jcode program -> JCode.jcode PP.t -> JCode.exception_handler list

  (** [exceptional_successors p pp] returns the list of program points
      that may be executed after [pp] if an exception (or error) occurs
      during the execution of [pp].  Note that its uses the [throws]
      annotation of the method, which is checked by the compiler but not
      by the bytecode verifier: for security analyses, the [throws]
      annotation should be checked by the analyses. *)
  (* TODO: implement a checker which checks if that the method declares
     all the exception it may throw (except subtypes of Error and
     RuntimeException). *)
  val exceptional_successors : JCode.jcode program -> JCode.jcode PP.t -> JCode.jcode PP.t list
    
  (** [static_lookup program pp] returns the highest methods in the
      hierarchy that may be called from program point [pp]. All
      methods that may be called at execution time are known to
      implement or extend one of the class that this function
      returns. *)
  val static_lookup : JCode.jcode program -> JCode.jcode PP.t
    -> (JCode.jcode node list * method_signature) option

  (** [get_successors program cl meth] returns the possible methods
      that may be invoked from the current program point (it uses
      [static_lookup'] function).  For the static initialization,
      only the topmost class initializer is returned (and the successors
      of a clinit methods includes the clinit methods that are
      beneath). *)
  val get_successors :
    JCode.jcode program ->
    JCode.jcode node -> JCode.jcode concrete_method -> ClassMethodSet.t
end

(** Manipulation of {!JBir.t} program pointers *)
module PP_Bir : sig
  (** [with type code =] {!JBir.t}*)
  include GenericPPSig with type code = JBir.t 

  val get_opcode : JBir.t PP.t -> JBir.instr

  (** returns the next instruction if there is one.  If there is not,
      the behavior is unspecified (specially if compiled with
      -unsafe...) *)
  val next_instruction : JBir.t PP.t -> JBir.t PP.t

  (** returns the normal intra-procedural successors of an
      instruction*)
  val normal_successors : JBir.t PP.t -> JBir.t PP.t list

  (** returns the handlers that could catch an exception thrown from
      the current instruction*)
  val handlers : JBir.t program -> JBir.t PP.t -> JBir.exception_handler list

  (** [exceptional_successors p pp] returns the list of program points
      that may be executed after [pp] if an exception (or error) occurs
      during the execution of [pp].  Note that its uses the [throws]
      annotation of the method, which is checked by the compiler but not
      by the bytecode verifier: for security analyses, the [throws]
      annotation should be checked by the analyses. *)
  (* TODO: implement a checker which checks if that the method declares
     all the exception it may throw (except subtypes of Error and
     RuntimeException). *)
  val exceptional_successors : JBir.t program -> JBir.t PP.t -> JBir.t PP.t list

  (** [static_lookup program pp] returns the highest methods in the
      hierarchy that may be called from program point [pp]. All
      methods that may be called at execution time are known to
      implement or extend one of the class that this function
      returns. *)
  val static_lookup : JBir.t program -> JBir.t PP.t
    -> (JBir.t node list * method_signature) option

  (** [get_successors program cl meth] returns the possible methods
      that may be invoked from the current program point (it uses
      [static_lookup'] function).  For the static initialization,
      only the topmost class initializer is returned (and the successors
      of a clinit methods includes the clinit methods that are
      beneath). *)
  val get_successors :
    JBir.t program ->
    JBir.t node -> JBir.t concrete_method -> ClassMethodSet.t
end

(** Manipulation of {!A3Bir.t} program pointers *)
module PP_A3Bir : sig
  (** [with type code =] {!A3Bir.t}*)
  include GenericPPSig with type code = A3Bir.t 

  val get_opcode : A3Bir.t PP.t -> A3Bir.instr

  (** returns the next instruction if there is one.  If there is not, the
      behavior is unspecified (specially if compiled with -unsafe...) *)
  val next_instruction : A3Bir.t PP.t -> A3Bir.t PP.t

  (** returns the normal intra-procedural successors of an
      instruction*)
  val normal_successors : A3Bir.t PP.t -> A3Bir.t PP.t list

  (** returns the handlers that could catch an exception thrown from
      the current instruction*)
  val handlers : A3Bir.t program -> A3Bir.t PP.t -> A3Bir.exception_handler list

  (** [exceptional_successors p pp] returns the list of program points
      that may be executed after [pp] if an exception (or error) occurs
      during the execution of [pp].  Note that its uses the [throws]
      annotation of the method, which is checked by the compiler but not
      by the bytecode verifier: for security analyses, the [throws]
      annotation should be checked by the analyses. *)
  (* TODO: implement a checker which checks if that the method declares
     all the exception it may throw (except subtypes of Error and
     RuntimeException). *)
  val exceptional_successors : A3Bir.t program -> A3Bir.t PP.t -> A3Bir.t PP.t list

    
  (** [static_lookup program pp] returns the highest methods in the
      hierarchy that may be called from program point [pp]. All
      methods that may be called at execution time are known to
      implement or extend one of the class that this function
      returns. *)
  val static_lookup : A3Bir.t program -> A3Bir.t PP.t
    -> (A3Bir.t node list * method_signature) option
    

  (** [get_successors program cl meth] returns the possible methods
      that may be invoked from the current program point (it uses
      [static_lookup'] function).  For the static initialization,
      only the topmost class initializer is returned (and the successors
      of a clinit methods includes the clinit methods that are
      beneath). *)
  val get_successors :
    A3Bir.t program ->
    A3Bir.t node -> A3Bir.t concrete_method -> ClassMethodSet.t  

end

(** Manipulation of {!JBirSSA.t} program pointers *)
module PP_BirSSA : sig
  (** [with type code =] {!JBirSSA.t}*)
  include GenericPPSig with type code = JBirSSA.t 

  (** [get_opcode pp] returns the couple [(phi_node list,
      instr)] corresponding to the program point [pp], phi nodes
      assignements must be executed before instruction*)
  val get_opcode : JBirSSA.t PP.t -> (JBirSSA.phi_node list * JBirSSA.instr)

  (** returns the next instruction if there is one.  If there is not,
      the behavior is unspecified (specially if compiled with
      -unsafe...) *)
  val next_instruction : JBirSSA.t PP.t -> JBirSSA.t PP.t

  (** returns the normal intra-procedural successors of an
      instruction*)
  val normal_successors : JBirSSA.t PP.t -> JBirSSA.t PP.t list

  (** returns the handlers that could catch an exception thrown from
      the current instruction*)
  val handlers : JBirSSA.t program -> JBirSSA.t PP.t -> JBirSSA.exception_handler list

  (** [exceptional_successors p pp] returns the list of program points
      that may be executed after [pp] if an exception (or error) occurs
      during the execution of [pp].  Note that its uses the [throws]
      annotation of the method, which is checked by the compiler but not
      by the bytecode verifier: for security analyses, the [throws]
      annotation should be checked by the analyses. *)
  (* TODO: implement a checker which checks if that the method declares
     all the exception it may throw (except subtypes of Error and
     RuntimeException). *)
  val exceptional_successors : JBirSSA.t program -> JBirSSA.t PP.t -> JBirSSA.t PP.t list

  (** [static_lookup program pp] returns the highest methods in the
      hierarchy that may be called from program point [pp]. All
      methods that may be called at execution time are known to
      implement or extend one of the class that this function
      returns. *)
  val static_lookup : JBirSSA.t program -> JBirSSA.t PP.t
    -> (JBirSSA.t node list * method_signature) option

  (** [get_successors program cl meth] returns the possible methods
      that may be invoked from the current program point (it uses
      [static_lookup'] function).  For the static initialization,
      only the topmost class initializer is returned (and the successors
      of a clinit methods includes the clinit methods that are
      beneath). *)
  val get_successors :
    JBirSSA.t program ->
    JBirSSA.t node -> JBirSSA.t concrete_method -> ClassMethodSet.t
end

(** Manipulation of {!JBirSSA.t} program pointers *)
module PP_A3BirSSA : sig
  (** [with type code =] {!A3BirSSA.t}*)
  include GenericPPSig with type code = A3BirSSA.t 

  (** [get_opcode pp] returns the couple [(phi_node list,
      instr)] corresponding to the program point [pp], phi nodes
      assignements must be executed before instruction*)
  val get_opcode : A3BirSSA.t PP.t -> (A3BirSSA.phi_node list * A3BirSSA.instr)

  (** returns the next instruction if there is one.  If there is not,
      the behavior is unspecified (specially if compiled with
      -unsafe...) *)
  val next_instruction : A3BirSSA.t PP.t -> A3BirSSA.t PP.t

  (** returns the normal intra-procedural successors of an
      instruction*)
  val normal_successors : A3BirSSA.t PP.t -> A3BirSSA.t PP.t list

  (** returns the handlers that could catch an exception thrown from
      the current instruction*)
  val handlers : A3BirSSA.t program -> A3BirSSA.t PP.t -> A3BirSSA.exception_handler list

  (** [exceptional_successors p pp] returns the list of program points
      that may be executed after [pp] if an exception (or error) occurs
      during the execution of [pp].  Note that its uses the [throws]
      annotation of the method, which is checked by the compiler but not
      by the bytecode verifier: for security analyses, the [throws]
      annotation should be checked by the analyses. *)
  (* TODO: implement a checker which checks if that the method declares
     all the exception it may throw (except subtypes of Error and
     RuntimeException). *)
  val exceptional_successors : A3BirSSA.t program -> A3BirSSA.t PP.t -> A3BirSSA.t PP.t list

  (** [static_lookup program pp] returns the highest methods in the
      hierarchy that may be called from program point [pp]. All
      methods that may be called at execution time are known to
      implement or extend one of the class that this function
      returns. *)
  val static_lookup : A3BirSSA.t program -> A3BirSSA.t PP.t
    -> (A3BirSSA.t node list * method_signature) option

  (** [get_successors program cl meth] returns the possible methods
      that may be invoked from the current program point (it uses
      [static_lookup'] function).  For the static initialization,
      only the topmost class initializer is returned (and the successors
      of a clinit methods includes the clinit methods that are
      beneath). *)
  val get_successors :
    A3BirSSA.t program ->
    A3BirSSA.t node -> A3BirSSA.t concrete_method -> ClassMethodSet.t
end


(** {3 Invoke lookup algorithms}*)

(** [invoke_virtual_lookup ?c ms instantiated_classes] returns the result of the
    InvokeVirtual instruction on a class [c] with the method signature [ms],
    given a set of possibly instantiated classes.

    Setting a value to [c] will only check (assert) that each class in
    [instantiated_classes] extends [c].  It raises an Assert_failure if the
    assertion fails and the program has been compiled without deactivating
    assertions. *)
val invoke_virtual_lookup : ?c:('a class_node option) -> method_signature ->
  'a class_node ClassMap.t -> ('a class_node * 'a concrete_method) ClassMethodMap.t

(** [invoke_interface_lookup ?i ms instantiated_classes] returns the result of
    the InvokeInterface instruction on an interface [i] with the method
    signature [ms], given a set of possibly instantiated classes.

    Setting a value to [i] will only check (assert) that each class in
    [instantiated_classes] implements [i] directly or indirectly.  It
    raises an Assert_failure if the assertion fails and the program
    has been compiled without deactivating assertions. *)
val invoke_interface_lookup : ?i:('a interface_node option) -> method_signature ->
  'a class_node ClassMap.t -> ('a class_node * 'a concrete_method) ClassMethodMap.t

(** [invoke_special_lookup current_class c ms] returns the result of
    the InvokeSpecial instruction on a class [c] with the method
    signature [ms], from the class [current_class]. *)
val invoke_special_lookup : 'a node -> 'a class_node ->
  method_signature -> 'a class_node * 'a concrete_method

(** [invoke_static_lookup c ms] returns the result of the InvokeStatic
    instruction on a class [c] with the method signature [ms]. *)
val invoke_static_lookup : 'a class_node -> method_signature ->
  'a class_node * 'a concrete_method

(** [static_lookup' program pp] returns a list of methods that may be
    called from program point [pp]. The computation is based on RTA or
    CHA, depending on the function used to build the program (it uses
    the field [program.static_lookup_method]). Caution: If the program
    code representation has been changed,
    [program.static_lookup_method] must have been updated at the same
    time (see {!JProgram.map_program} function).*)
val static_lookup' : 'a program -> 'a PP.t -> 'a PP.t list

