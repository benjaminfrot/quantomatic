(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- *) 
(*  GHZ/W graphs, vertices can be black or white and have unit data *)
(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- *) 
structure RGB_GraphParam
: GRAPH_PARAM
= struct

  structure VData = RGB_VertexData;

  (* edges have unit data, and are ignored as we use Vertex subst type *)
  structure EData = 
    IgnoredUnifiableData(structure D = UnitData structure S = VData
                         val default_data = ());
  
  (* vertex, and vertex data variable dependencies *)
  structure VDep = VXBRel;
  
  (* internal name data *)
  type T = VDep.T;

  (* IMPROVE: what data do we want here? should it be add_exp *)
  exception match_exp of unit;
  exception unknown_type_exp of string;

  fun get_xnames vdep = VDep.get_codset vdep;
  fun get_vnames vdep = VDep.get_domset vdep;

  fun try_rename1_xname n1 n2 vdep = VDep.try_rename1_cod n1 n2 vdep;
  fun try_rename1_vname n1 n2 vdep = VDep.try_rename1_dom n1 n2 vdep;

  fun rename_vname n1 n2 vdep = 
      (case VDep.try_rename1_dom n1 n2 vdep of NONE => 
         raise V.Rnm.invalid_renaming_exp "RGB_GraphParam.rename_vname"
       | SOME x => x);

  fun rename_ename n1 n2 vdep = vdep;
  
  (* rename names in T *)

  (* rename internal names in the dependency structure *)
  structure CRnmX : COMPOUND_RENAMING
  = CompoundRenamingFun(
    struct structure Nm = X
           type obj = T
           val get_nameset = get_xnames
           val try_rename1 = try_rename1_xname
    end);

  (* rename vertices in the dependency structure *)
  structure CRnmV : COMPOUND_RENAMING
  = CompoundRenamingFun(
    struct structure Nm = V
           type obj = T
           val get_nameset = get_vnames
           val try_rename1 = try_rename1_vname
    end);

  (* rename edges in the dependency structure *)
  structure CRnmE : COMPOUND_RENAMING
  = EmptyCompoundRenamingFun(structure Nm = E type obj = T);

  (* empty name-dependency information *)
  val empty = VDep.empty;

  fun add_vertex vd vn vdep = vdep;
  fun add_edge ed en vdep = vdep;

  fun delete_vertex vn vdep = vdep;
  fun delete_edge en vdep = vdep;

  fun replace_vertex vd vn vdep = 
      vdep |> delete_vertex vn
           |> add_vertex vd vn;
  fun replace_edge ed en vdep = vdep;

  fun of_vertex vd vn = add_vertex vd vn VDep.empty;
  fun of_edge en ed = empty;

  (* renaming internal names within a vertex *)
  structure VDataCRnmX : COMPOUND_RENAMING
  = struct 
    type obj = VData.data
    type renaming = X.Rnm.T

    val empty_renaming = CRnmX.empty_renaming

    fun rename rnm vd = (rnm,vd);
    fun mk_renaming vd rnm = rnm;
    fun do_renaming rnm vd = vd;
    val restrict_to_avoiding = X.Rnm.restrict_to_avoiding;
  end;

  (* rename internal names within an edge data *)
  structure EDataCRnmX : COMPOUND_RENAMING
  = EmptyCompoundRenamingFun(structure Nm = X type obj = EData.data);

  (* substitutions for variables in vertex/edge data 
     (usually, we only have data on vertices) *)
  type subst = VData.subst; (* : LinratExpr.T IName.NTab.T; *)

  val empty_subst = VData.empty_subst; (* : IName.NTab.empty; *)
  fun compose_subst u1 u2 = VData.compose_subst (u1,u2); 
      (* : Name.NTab.map_all (LinratExpr.subs u2) u1; *)

  fun try_match_vertex d1 d2 u = VData.match_data (d1,d2) u;
  fun try_match_edge e1 e2 u = SOME u;

  (* raises match_exp *)
  fun match_vertex d1 d2 u = 
      (case try_match_vertex d1 d2 u 
         of NONE    => raise match_exp ()
          | SOME u' => u'); 
  
  fun match_edge d1 d2 u =
      (case try_match_edge d1 d2 u 
         of NONE    => raise match_exp ()
          | SOME u' => u'); 

  fun subst_in_vertex u vd = VData.subst_in_data u vd;
  fun subst_in_edge u ed = ed;

  val pretty_subst = VData.pretty_subst;
  val print_subst = Pretty.writeln o pretty_subst;

  val pretty_theory_name = Pretty.str "red_green_blue";

  structure Sharing = 
  struct 
    structure VData = VData.Sharing;
    structure EData = EData.Sharing;
    type T = T;
    type inames_renaming = CRnmX.renaming; (* = IName.Rnm.renaming *)
    type subst = subst;
  end;
end;

structure RGB_OVertexData = OVertexData(RGB_VertexData);
structure RGB_OGraphParam = OGraphParam(
  structure Param = RGB_GraphParam 
        and OVData = RGB_OVertexData);

structure RGB_OVertexComponentData_Param = OVertexComponentData_Param(
  structure VertexDataParam = RGB_VertexComponentData_Param
  structure OVData = RGB_OVertexData);

structure RGB_OVertexComponentData = ElementComponentData(RGB_OVertexComponentData_Param);


