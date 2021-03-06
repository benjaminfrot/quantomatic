(* controller state *)
signature CONTROLLER_STATE =
sig
  type T;
  structure Theory : GRAPHICAL_THEORY;
  type rewrite = (R.name * Theory.Rule.T) * Theory.Graph.T
  type vertex = (Theory.OVData.data * (E.NSet.T * E.NSet.T));
  type edge = ((Theory.Graph.dir_or_undir * Theory.EData.data) * (V.name * V.name));

  exception no_such_graph_exp of GraphName.name;
  exception no_such_vertex_exp of (V.name * GraphName.name);
  exception no_such_vertex_type_exp of string;
  exception no_such_edge_exp of (E.name * GraphName.name);
  exception no_such_edge_type_exp of string;
  exception no_such_bbox_exp of (B.name * GraphName.name);
  exception no_such_rule_exp of R.name;
  exception no_such_tag_exp of TagName.name;
  exception vertex_name_exists_exp of (V.name * GraphName.name);
  exception edge_name_exists_exp of (E.name * GraphName.name);
  exception bbox_name_exists_exp of (B.name * GraphName.name);
  exception bad_rule_exp of string;
  exception bad_state_exp of string;
  exception out_of_bounds_exp of int;

  val init : T (* initial empty state, no graphs *)

  (* get/set*)
  val get_rset : T -> Theory.Ruleset.T
  val get_rewrites : T -> rewrite list GraphName.NTab.T;
  val get_hist : T -> (Theory.Graph.T list * Theory.Graph.T list) GraphName.NTab.T;
  val get_graphs : T -> Theory.Graph.T GraphName.NTab.T;
  val get_graph : T -> GraphName.name -> Theory.Graph.T;
  val get_graph_names : T -> GraphName.name list;

  val update_rset : (Theory.Ruleset.T -> Theory.Ruleset.T) -> T -> T
  val update_rewrites :
   (rewrite list GraphName.NTab.T -> rewrite list GraphName.NTab.T) ->
     T -> T
  val update_hist :
   ((Theory.Graph.T list * Theory.Graph.T list) GraphName.NTab.T ->
     (Theory.Graph.T list * Theory.Graph.T list) GraphName.NTab.T) -> T -> T
  val update_graphs :
   (Theory.Graph.T GraphName.NTab.T -> Theory.Graph.T GraphName.NTab.T) -> T -> T

  val set_rset : Theory.Ruleset.T -> T -> T
  val set_rewrites : rewrite list GraphName.NTab.T -> T -> T
  val set_hist : (Theory.Graph.T list * Theory.Graph.T list) GraphName.NTab.T -> T -> T
  val set_graphs : Theory.Graph.T GraphName.NTab.T -> T -> T
  val set_graph : Theory.Graph.T -> GraphName.name -> T -> T



  (* history *)
  val undo : GraphName.name -> T -> T
  val redo : GraphName.name -> T -> T
  val push_hist : GraphName.name -> T -> T

  (* printing/showing info (for console) *)
  val get_attached_rewrites : GraphName.name -> T -> rewrite list
  val list_rules_with_tag : TagName.name -> T -> TagName.name list
  val list_allrules : T -> R.name list
  val list_tags : T -> TagName.name list
  val list_active_rules : T -> R.name list

  (* rewriting *)
  val attach_rewrites : GraphName.name -> V.name list -> T -> int * T
  val attach_first_rewrite : GraphName.name -> V.name list -> T -> int * T
  val apply_rewrite : GraphName.name -> int -> T -> T
  val apply_first_rewrite : GraphName.name -> T -> T

  (* rules/rulsesets *)
  val set_rule : R.name -> GraphName.name -> GraphName.name -> T -> T
  val open_rule_lhs : T -> R.name -> GraphName.name * T
  val open_rule_rhs : T -> R.name -> GraphName.name * T
  val delete_tag_and_its_rules : TagName.name -> T -> T
  val delete_tag : TagName.name -> T -> T
  val delete_rules_in_tag : TagName.name -> T -> T
  val delete_rule : R.name -> T -> T

  val activate_rules_with_tag : TagName.name -> T -> T
  val activate_rule : R.name -> T -> T
  val deactivate_rules_with_tag : TagName.name -> T -> T
  val deactivate_rule : R.name -> T -> T

  val tag_rule : R.name -> TagName.name -> T -> T
  val untag_rule : R.name -> TagName.name -> T -> T

  (* graphs and their manipulations *)
  val kill_graph : GraphName.name -> T -> T
  val insert_graph : GraphName.name -> GraphName.name -> T -> T
  val update_graph_user_data : GraphName.name -> string -> string -> T -> T
  val add_graph : GraphName.name -> Theory.Graph.T -> T -> GraphName.name * T
  val copy_subgraph : GraphName.name -> GraphName.name -> V.name list -> T -> T

  val add_vertex : string -> GraphName.name -> T -> (V.name * vertex) * T
  val add_edge : string -> Theory.Graph.dir_or_undir  -> V.name -> V.name -> GraphName.name -> T -> (E.name * edge) * T
  val add_bang : GraphName.name -> T -> B.name * T

  val update_vertex_data : (Theory.OVData.data -> Theory.OVData.data) -> V.name -> GraphName.name -> T -> T
  val update_vertex_user_data : string -> string -> V.name -> GraphName.name -> T -> T
  val update_edge_data : (Theory.EData.data -> Theory.EData.data) -> E.name -> GraphName.name -> T -> T
  val rename_vertex : V.name -> V.name -> GraphName.name -> T -> T
  val rename_edge : E.name -> E.name -> GraphName.name -> T -> T
  val rename_bang : B.name -> B.name -> GraphName.name -> T -> T
  val rename_graph : GraphName.name -> GraphName.name -> T -> GraphName.name * T
  val delete_vertices : V.name list -> GraphName.name -> T -> T
  val delete_edges : E.name list -> GraphName.name -> T -> T

  val bang_vertices : B.name -> V.name list -> GraphName.name -> T -> T
  val kill_bang : B.name list -> GraphName.name -> T -> T
  val unbang_vertices : V.name list -> GraphName.name -> T -> T
  val merge_bang : B.name list -> GraphName.name -> T -> B.name * T
  val duplicate_bang : B.name -> GraphName.name -> T -> B.name * T
  val drop_bang : B.name list -> GraphName.name -> T -> T

end;


(* controls the state of Quantomatic *)
functor ControllerState(GraphicalTheory : GRAPHICAL_THEORY)
= struct


  structure Theory = GraphicalTheory;
  structure RulesetRewrites = Theory.RulesetRewrites
  structure Ruleset = Theory.Ruleset;
  structure Rule = Theory.Rule;
  structure Graph = Theory.Graph;
  structure OVData = Graph.OVData;
  structure EData = Graph.EData;

  exception no_such_graph_exp of GraphName.name;
  exception no_such_graph_user_data_exp of (GraphName.name * string);
  exception no_such_vertex_user_data_exp of (V.name * string);
  exception no_such_vertex_exp of (V.name * GraphName.name);
  exception no_such_vertex_type_exp of string;
  exception no_such_edge_exp of (E.name * GraphName.name);
  exception no_such_edge_type_exp of string;
  exception no_such_bbox_exp of (B.name * GraphName.name);
  exception no_such_rule_exp of R.name;
  exception no_such_tag_exp of TagName.name;
  exception vertex_name_exists_exp of (V.name * GraphName.name);
  exception edge_name_exists_exp of (E.name * GraphName.name);
  exception bbox_name_exists_exp of (B.name * GraphName.name);
  exception bad_rule_exp of string;
  exception bad_state_exp of string;
  exception out_of_bounds_exp of int;

  type rewrite = (R.name * Rule.T) * Graph.T (* rule, and graph to be rewritten to *)
  type vertex =  (OVData.data * (E.NSet.T * E.NSet.T));
  type edge = ((Graph.dir_or_undir * EData.data) * (V.name * V.name));

  (* data for controller; top level data with which user interacts *)
  datatype T = CState of {
       graphs : Graph.T GraphName.NTab.T, (* the known graphs *)
       rewrites : (rewrite list) GraphName.NTab.T, (* cached possible rewrites *)
       hist : (Graph.T list * Graph.T list) GraphName.NTab.T, (* past and future *)
       rset : Ruleset.T (* the known rules *)
  }

  (* getters and setters for the state *)
  fun update_graphs f (CState {graphs=g,rewrites=r,hist=h,rset=t}) = 
    CState {graphs=(f g),rewrites=r,hist=h,rset=t}
  fun update_rewrites f (CState {graphs=g,rewrites=r,hist=h,rset=t}) =
    CState {graphs=g,rewrites=(f r),hist=h,rset=t}
  fun update_hist f (CState {graphs=g,rewrites=r,hist=h,rset=t}) = 
    CState {graphs=g,rewrites=r,hist=(f h),rset=t}
  fun update_rset f (CState {graphs=g,rewrites=r,hist=h,rset=t}) = 
    CState {graphs=g,rewrites=r,hist=h,rset=(f t)}
  val (set_graphs,set_rewrites,set_hist,set_rset) = 
    (update_graphs o K, update_rewrites o K, update_hist o K, update_rset o K)
  fun get_graphs (CState {graphs=g,...}) = g
  fun get_rewrites (CState {rewrites=r,...}) = r
  fun get_hist (CState {hist=h,...}) = h
  fun get_rset (CState {rset=t,...}) = t

  val init = CState {graphs=GraphName.NTab.empty,
                         rewrites=GraphName.NTab.empty,
                         hist=GraphName.NTab.empty,
                         rset=Ruleset.empty};

  (* state accessors *)
  fun get_graph state name =
      (case GraphName.NTab.lookup (get_graphs state) name
       of SOME g => g
        | NONE => raise no_such_graph_exp name)

  val get_graph_names = GraphName.NSet.list_of o GraphName.NTab.get_nameset o get_graphs

  (* state mutators *)
  fun push_hist gname state = 
      let
        val (back,_) = 
            the_default ([],[]) (GraphName.NTab.lookup (get_hist state) gname)
        val hist' = (get_hist state)
                          |> GraphName.NTab.update
                          (gname,((get_graph state gname)::back, []))
      in state |> set_hist hist'
      end

  (* any time the graph is changed, any attached rewrites are invalid,
   * so should be cleared *)
  fun set_graph graph' gname state =
      state |> update_graphs (GraphName.NTab.update (gname,graph'))
              |> update_rewrites (GraphName.NTab.update (gname,[]))    


  (* ============================================== *)
  (* these functions actually implement commmands *)

  (* common things we want to assert are true *)
  fun assert_tag_exists state tag_name = 
      if Ruleset.tag_exists (get_rset state) tag_name then ()
      else raise no_such_tag_exp tag_name;

  fun assert_rule_exists state rule_name = 
      if Ruleset.rule_exists (get_rset state) rule_name then ()
      else raise no_such_rule_exp rule_name;

  fun assert_vertex_exists state gname vname =
        if Graph.has_vname (get_graph state gname) vname then ()
        else raise no_such_vertex_exp (vname, gname);

  fun assert_vertex_exists_gr graph vname =
        if Graph.has_vname graph vname then ()
        else raise Graph.no_such_vname_exp ("ASSERT", vname, graph);

  fun assert_edge_exists state gname ename =
        if Graph.has_ename (get_graph state gname) ename then ()
        else raise no_such_edge_exp (ename, gname);

  fun assert_edge_exists_gr graph ename =
        if Graph.has_ename graph ename then ()
        else raise Graph.no_such_ename_exp ("ASSERT", ename, graph);

  fun assert_bbox_exists state gname bname =
        if Graph.has_bname (get_graph state gname) bname then ()
        else raise no_such_bbox_exp (bname, gname);


  (* basic stuff on rule tags *)
  val list_allrules =
      R.NSet.list_of o R.NTab.get_nameset o Ruleset.get_allrules o get_rset

  val list_active_rules =
      R.NSet.list_of o Ruleset.get_active o get_rset

  val list_tags =
      TagName.NSet.list_of o Ruleset.get_tags o get_rset

  fun list_rules_with_tag tag_name state =
    if Ruleset.tag_exists (get_rset state) tag_name
    then
      let
        val rule_name_set = TagRel.codf (Ruleset.get_tagrel (get_rset state)) tag_name
      in
        R.NSet.list_of rule_name_set
      end
    else
      []

  fun tag_name_action f tag_name state =
      let val () = assert_tag_exists state tag_name
      in update_rset (f tag_name) state end
  val deactivate_rules_with_tag = tag_name_action Ruleset.deactivate_tag; 
  val activate_rules_with_tag = tag_name_action Ruleset.activate_tag


  fun rule_name_action f rule state = 
      let val () = assert_rule_exists state rule
      in update_rset (f rule) state end
  val deactivate_rule  = rule_name_action Ruleset.deactivate_rule
  val activate_rule = rule_name_action Ruleset.activate_rule
  val delete_rule = rule_name_action Ruleset.delete_rule

  (* creates/replaces rule *)
  fun set_rule rule_name lhs rhs state =
      let
        (* build graphs for the LHS and RHS *)
        val lgr = get_graph state lhs
        val rgr = get_graph state rhs
        val rule = Ruleset.Rule.mk (lgr, rgr)
      in
        state |> update_rset (Ruleset.update_rule (rule_name, rule))
      end
      handle Ruleset.Rule.bad_rule_exp _ =>
            raise bad_rule_exp "Boundaries and !-boxes on LHS must match RHS."

  fun delete_tag tag_name state =
      let val () = assert_tag_exists state tag_name
      in update_rset (Ruleset.delete_tag tag_name) state end

  fun delete_rules_in_tag tag_name state =
      let val () = assert_tag_exists state tag_name
      in update_rset (Ruleset.delete_rules_in_tag tag_name) state end

  fun delete_tag_and_its_rules tag_name state =
      let val () = assert_tag_exists state tag_name
      in update_rset (Ruleset.delete_tag tag_name
                                   o Ruleset.delete_rules_in_tag tag_name) state end

  fun tag_rule rule_name tag_name state = 
      let val () = assert_rule_exists state rule_name
      in update_rset (Ruleset.tag_rule rule_name tag_name) state end

  fun untag_rule rule_name tag_name state = 
      let val () = assert_rule_exists state rule_name
          val () = assert_tag_exists state tag_name
      in update_rset (Ruleset.untag_rule rule_name tag_name) state end


    fun add_graph default_name graph state = let
        val (nm,gs) = (get_graphs state)
                  |> GraphName.NTab.add (default_name, graph)
        in (nm, state |> set_graphs gs) end

  fun kill_graph name state =
      (update_graphs (fn gs => gs |> GraphName.NTab.delete name) state)
       handle GraphName.NTab.Tab.UNDEF _ => raise no_such_graph_exp name

  fun rename_graph oldname newname state =
     (let
          val graphs = get_graphs state
          val gr = GraphName.NTab.get graphs oldname
          val (nm,graphs') = graphs
                    |> GraphName.NTab.delete oldname
                    |> GraphName.NTab.add (newname, gr)
      in
        (nm, set_graphs graphs' state)
      end
      handle GraphName.NTab.Tab.UNDEF _ => raise no_such_graph_exp oldname)

  fun lift_graph_mutator cmdf gname state =
      let val (out,g') = cmdf (get_graph state gname)
      in
        (out, state |> push_hist gname 
                    |> set_graph g' gname)
      end
      handle Graph.no_such_vname_exp (_,vname,_) =>
               raise no_such_vertex_exp (vname,gname)
           | Graph.no_such_ename_exp (_,ename,_) =>
               raise no_such_edge_exp (ename,gname)
           | Graph.vname_already_exists_exp (vname,_) =>
                raise vertex_name_exists_exp (vname,gname)
           | Graph.ename_already_exists_exp (ename,_) =>
                raise edge_name_exists_exp (ename,gname)
           | Graph.bname_already_exists_exp (bname,_) =>
                raise bbox_name_exists_exp (bname,gname);

  fun lift_graph_mutator_no_result cmdf gname state =
      let val g' = cmdf (get_graph state gname)
      in
        state |> push_hist gname
              |> set_graph g' gname
      end
      handle Graph.no_such_vname_exp (_,vname,_) =>
               raise no_such_vertex_exp (vname,gname)
           | Graph.no_such_ename_exp (_,ename,_) =>
               raise no_such_edge_exp (ename,gname)
           | Graph.vname_already_exists_exp (vname,_) =>
                raise vertex_name_exists_exp (vname,gname)
           | Graph.ename_already_exists_exp (ename,_) =>
                raise edge_name_exists_exp (ename,gname)
           | Graph.bname_already_exists_exp (bname,_) =>
                raise bbox_name_exists_exp (bname,gname);

  fun add_vertex_internal vt graph =
      (let val (n,g) = graph |> Graph.add_vertex (Theory.VertexComponentData.default_data vt) in
          ((n,Graph.get_vertex g n), g)
       end
       handle Theory.VertexComponentData.unknown_type_exp _ => raise no_such_vertex_type_exp vt)
  fun add_vertex vt gname state = lift_graph_mutator (add_vertex_internal vt) gname state

  fun add_edge_internal et dir_or_undir v1 v2 graph =
      (let val (n,g) = graph |> Graph.add_edge (dir_or_undir,Theory.EdgeComponentData.default_data et) v1 v2
       in ((n,Graph.get_edge g n), g)
       end
       handle Theory.EdgeComponentData.unknown_type_exp _ => raise no_such_edge_type_exp et)

  fun add_edge et dir_or_undir v1 v2 gname state = lift_graph_mutator
  (add_edge_internal et dir_or_undir v1 v2) gname state


  fun delete_vertices vs =
    lift_graph_mutator_no_result (fold Graph.delete_vertex vs)

  fun delete_edges es =
    lift_graph_mutator_no_result (fold Graph.delete_edge es)

  fun rename_vertex_internal old new graph = (graph |> Graph.rename_vname old new)
  fun rename_vertex old new graph state = lift_graph_mutator_no_result (rename_vertex_internal old new) graph state

  fun rename_edge_internal old new graph = (graph |> Graph.rename_ename old new)
  fun rename_edge old new graph state = lift_graph_mutator_no_result (rename_edge_internal old new) graph state

  fun rename_bang_internal old new graph = (graph |> Graph.rename_bname old new)
  fun rename_bang old new graph state = lift_graph_mutator_no_result (rename_bang_internal old new) graph state


  fun undo gname state =
      let
        val current = get_graph state gname
      in case GraphName.NTab.lookup (get_hist state) gname
          of SOME (g::gs, hs) =>
              state |> set_graph g gname
                    |> update_hist (GraphName.NTab.update
                                   (gname, (gs,current::hs)))
           | _ => raise bad_state_exp "Can't undo, no more undo history."
      end

  fun redo gname state = 
      let
        val current = get_graph state gname
      in case GraphName.NTab.lookup (get_hist state) gname
          of SOME (gs, h::hs) =>
              state |> set_graph h gname
                    |> update_hist (GraphName.NTab.update
                                   (gname, (current::gs,hs)))
           | _ => raise bad_state_exp "Can't redo, nothing to redo."
      end

  fun apply_rewrite gname n state =
      (let val rewrites = GraphName.NTab.get (get_rewrites state) gname
           val (_,rewritten_graph) = nth rewrites n
       in state |> push_hist gname
                |> set_graph rewritten_graph gname
       end
       handle GraphName.Tab.UNDEF _ => raise bad_state_exp "No rewrites attached." 
            | General.Subscript => raise out_of_bounds_exp n)

  local
      fun attach_with attacher gname vs state =
          (let val vset = fold V.NSet.ins_fresh vs V.NSet.empty
               val graph = get_graph state gname
               val rws = (Seq.list_of (attacher (get_rset state) graph vset))
           in
               (length rws,
                state |> update_rewrites (GraphName.NTab.update (gname,rws)))
           end)

      fun apply_first_in rset vs g = 
          case RulesetRewrites.apply_first_in rset vs g of NONE => Seq.empty
          | SOME x => Seq.single x;
  in
  val attach_rewrites = attach_with RulesetRewrites.apply_in;
  val attach_first_rewrite = attach_with apply_first_in; 

  fun apply_first_rewrite gname state = 
      let
        val graph = get_graph state gname 
        val (n,state') = attach_with apply_first_in gname (V.NSet.list_of (Graph.get_vnames graph)) state
      in if n = 0 then raise bad_state_exp "No more rewrites."
         else apply_rewrite gname 0 state'
      end
  end

  fun get_attached_rewrites gname state = let
      val rewrites = case GraphName.NTab.lookup (get_rewrites state) gname
              of NONE => raise bad_state_exp "No rewrites attached."
               | SOME rs => rs
  in rewrites end;

  fun update_vertex_data_internal vd_upd vn graph =
      let val () = assert_vertex_exists_gr graph vn in
        graph |> Graph.update_vertex_data vd_upd vn
      end
  fun update_vertex_data vd_upd vn = lift_graph_mutator_no_result (update_vertex_data_internal vd_upd vn)
  
  fun update_vertex_user_data_internal dn ud vn g =
      let
        val () = assert_vertex_exists_gr g vn
        val updater = Symtab.update (dn, ud)
        val brel = Graph.get_vertices_u_d_brel g
        fun get_uv_name v = case (VVUDBRel.lookup_domf brel v)
          of SOME x => (case (UV.NSet.get_first x) 
            of SOME y => y
             | NONE => 
                raise no_such_vertex_user_data_exp (vn, "No such user data."))
           | NONE => 
              raise no_such_vertex_user_data_exp (vn, "No such user data.")
      in
        Graph.update_vertex_user_data updater (get_uv_name vn) g
      end;
  fun update_vertex_user_data dn ud vn = lift_graph_mutator_no_result
    (update_vertex_user_data_internal dn ud vn)

  fun update_edge_data_internal ed_upd en graph =
      let val () = assert_edge_exists_gr graph en in
        graph |> Graph.update_edge_data ed_upd en
      end
  fun update_edge_data ed_upd en = lift_graph_mutator_no_result (update_edge_data_internal ed_upd en)

  fun add_bang_internal graph = 
      graph |> Graph.new_box (B.default_name)
  val add_bang = lift_graph_mutator add_bang_internal

  fun drop_bang bs gname state =
      let val _ = map (assert_bbox_exists state gname) bs in
        lift_graph_mutator_no_result (fold Graph.drop_box bs) gname state
      end

  fun kill_bang bs gname state =
      let val _ = map (assert_bbox_exists state gname) bs in
        lift_graph_mutator_no_result (fold Graph.kill_box bs) gname state
      end

  fun merge_bang bs gname state =
      let val _ = map (assert_bbox_exists state gname) bs in
        lift_graph_mutator (Graph.merge_boxes (B.NSet.of_list bs)) gname state
      end

  fun duplicate_bang bb gname state =
      let val _ = assert_bbox_exists state gname bb in
        lift_graph_mutator (Graph.fresh_copy1_box bb) gname state
      end

  fun bang_vertices box verts gname state =
      let val _ = assert_bbox_exists state gname box
          val _ = map (assert_vertex_exists state gname) verts
      in
        lift_graph_mutator_no_result (Graph.move_to_box box (V.NSet.of_list verts)) gname state
      end

  fun unbang_vertices verts gname state =
      let val _ = map (assert_vertex_exists state gname) verts in
        lift_graph_mutator_no_result (Graph.move_to_unbox (V.NSet.of_list verts)) gname state
      end

  fun copy_subgraph source target vs state = let
      val _ = map (assert_vertex_exists state source) vs
      val clip = Graph.delete_subgraph_outside_vset 
                   (V.NSet.of_list vs)
                   (get_graph state source)
  in state |> set_graph clip target
  end

  fun insert_graph sname tname state = 
      let
        val sarg = get_graph state sname
        val targ = get_graph state tname
        val (_, source) = Graph.rename_apart targ sarg
      in state |> push_hist tname
                            |> set_graph (Graph.merge_by_vertices targ source) tname
      end

  fun update_graph_user_data gname dname udata state =
    lift_graph_mutator_no_result (Graph.update_graph_user_data (Symtab.update
        (dname,udata))) gname state

  fun graph_of_rule getter label state rulename =
      let
        val rset = get_rset state
        val r = case R.NTab.lookup (Ruleset.get_allrules rset) rulename
                     of SOME v => v | NONE => raise no_such_rule_exp rulename
        val (name, graphs) = GraphName.NTab.add (GraphName.mk ((R.dest rulename)^"_"^label), getter r) (get_graphs state)
      in
        (name, state |> set_graphs graphs)
      end

  val open_rule_lhs = graph_of_rule Rule.get_lhs "lhs"
  val open_rule_rhs = graph_of_rule Rule.get_rhs "rhs"

end; (* structure Controller *)

(* vim:et:sts=2:sw=2
*)
