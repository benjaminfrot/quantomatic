(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-==-=-=-=-=-=-=-=-=-=- *) 
(*  Representation Graphs with  Bang-Boxes *)
(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-==-=-=-=-=-=-=-=-=-=- *) 
(* FIXME: make merge_by_vertices respect !-boxes. ? need general notion of 
   data merging? *)

(* Basic Bang Graphs: data and also basic functions *)
signature BASIC_BANG_GRAPH = 
sig
include BASIC_OGRAPH;

val get_bboxes : T -> VBMap.T
val get_bbox : T -> B.name -> V.NSet.T
val get_bbox_list : T -> B.name list
val get_unboxed : T -> V.NSet.T

exception bname_already_exists_exp of B.name * T;
val rename_bname : B.name -> B.name -> T -> T
val try_rename1_bname : B.name -> B.name -> T -> T option

val update_unboxed : (V.NSet.T -> V.NSet.T) -> T -> T
val update_bboxes : (VBMap.T -> VBMap.T) -> T -> T

val set_unboxed : V.NSet.T -> T -> T
val set_bboxes : VBMap.T -> T -> T

val add_to_unboxed : V.name -> T -> T
val del_from_unboxed : V.name -> T -> T

end;



(* bang-box graphs with all the extra functions defined in terms of the 
   basic ones *)
signature BANG_GRAPH = 
sig
include OGRAPH;

(* *** COPIED FROM BASIC_BANG_GRAPH ... would be better to have union version 
   of include *** *)

exception merge_bbox_exp of string 
exception overlapping_bbox_exp of V.NSet.T * T
exception no_such_bbox_exp of unit
exception bname_already_exists_exp of B.name * T;

val get_bboxes : T -> VBMap.T
val get_bbox : T -> B.name -> V.NSet.T
val get_bbox_list : T -> B.name list
val get_unboxed : T -> V.NSet.T
val get_boxed : T -> V.NSet.T
val rename_bname : B.name -> B.name -> T -> T
val try_rename1_bname : B.name -> B.name -> T -> T option
(* val rename_bbname : B.name -> B.name -> T -> T *)

val update_unboxed : (V.NSet.T -> V.NSet.T) -> T -> T
val update_bboxes : (VBMap.T -> VBMap.T) -> T -> T
val set_unboxed : V.NSet.T -> T -> T

(* val add_to_unboxed : V.NSet.T -> T -> T;
val del_from_unboxed : V.NSet.T -> T -> T;
*)
val set_bboxes : VBMap.T -> T -> T;

(* *** END OF COPIED *** *)

val get_bbnames : T -> B.NSet.T
val add_to_bbnames : T -> B.NSet.T -> B.NSet.T

val lookup_box_of : T -> V.name -> B.name option
val get_box_of : T -> V.name -> B.name

val is_boxed : T -> V.name -> bool

val has_bname : T -> B.name -> bool

val new_box : B.name -> T -> B.name * T
val move_to_box : B.name -> V.NSet.T -> T -> T
val move_to_unbox : V.NSet.T -> T -> T


val kill_box : B.name -> T -> T
val drop_box : B.name -> T -> T
val merge_boxes : B.NSet.T -> T -> B.name * T


val copy1_box : B.name (* bbox to copy *) 
      -> ((V.renaming (* renaming for bbox copy/avoids *)
           * E.renaming 
           * B.renaming) 
          * T) (* graph containing bbox name *) 
      -> (B.name (* new box name *)
          * ((V.renaming (* how vnames were copied *)
               * E.renaming (* ename copying *)
               * B.renaming) (* bbname copying *)
             * T)) (* new graph with bbox copied *)

val fresh_copy1_box : B.name (* bbox to copy *) 
      -> T (* graph containing bbox name *) 
      -> (B.name (* new box name *)
          * T) (* new graph with bbox copied *)

(* *)
val get_filtered_adj_arities_and_bang_arities : 
    (((H.name * (dir_or_undir * EData.data)) * V.name) -> bool)
    -> T -> V.name 
    -> Arity.T V.NTab.T  
       * Arity.T V.NTab.T B.NTab.T

(* *)
val get_adj_arities_and_bang_arities : 
    T -> V.name 
    -> Arity.T V.NTab.T  
       * Arity.T V.NTab.T B.NTab.T

(* adjacent vertex info, w.r.t. tgt and pattern for matching *)
val adj_tgt_info_bangs : 
    T -> V.name 
    -> VData.data 
       * (EData.data E.NTab.T (* names/data of edges that are self-loops *)
          * (VBMap.T (* bang box to contained adj vertices *)
             * V.NSet.T)) (* other adj vertices *)

(* like tgt, but includes separation of boundary vertices *)
val adj_pat_info_bangs :
    T -> V.name 
    -> VData.data 
       * ((H.name * EData.data)
            V.NTab.T (* leaf vertex to source's half-edge *)
          * EData.data E.NTab.T (* names of edges that are self-loops *)
          * (VBMap.T  (* bang box to contained adj vertices *)
             * V.NSet.T)) (* other adj vertices *)

(* renaming of bang-box names *)
structure BBoxCRnm : COMPOUND_RENAMING 
where type obj = T and type renaming = B.Rnm.T

end;


(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-==-=-=-=-=-=-=-=-=-=- *) 
(* A  Graph With Boundary *)
(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-==-=-=-=-=-=-=-=-=-=- *) 
functor BasicBangGraphFun(
        structure Param : OGRAPH_PARAM
        type data 
        val empty_data : data
) : BASIC_BANG_GRAPH
= struct

  (* IDEA: would be handy to have a warning for type overloading; can be tricky to see! e.g. if OVertex = Param.Vertex ... *)
  
  (* to avoid using clobbered data and empty graph from the opened Basic Graph *)
  type data2 = data;
  val empty_data2 = empty_data;
  
  (* we add bbox to Graph data, this is hidden *)
  datatype hdata = 
           HData of 
           { bboxes : VBMap.T,
             unboxed : V.NSet.T,
             data : data
           };
  fun get_unboxed_of_hdata (HData rep) = #unboxed rep;
  fun get_bboxes_of_hdata (HData rep) = #bboxes rep;
  fun get_data_of_hdata (HData rep) = #data rep;
  fun update_bboxes_of_hdata f (HData rep) =
      HData { data = #data rep,
              bboxes = f (#bboxes rep),
              unboxed = #unboxed rep
            };
  fun update_data_of_hdata f (HData rep) =
      HData { data = f (#data rep),
              bboxes = #bboxes rep,
              unboxed = #unboxed rep
            };
  fun update_unboxed_of_hdata f (HData rep) =
      HData { data = #data rep,
              bboxes = #bboxes rep,
              unboxed = f (#unboxed rep)
            };
  val empty_hdata = HData {bboxes = VBMap.empty,
                     unboxed = V.NSet.empty,
                     data = empty_data};

  (* make basic graph with this as internal data *)
  structure G : BASIC_OGRAPH = BasicOGraphFun(
    structure Param = Param
    type data = hdata
    val empty_data = empty_hdata
  );
  (* inherit functions from Graph *)
  open G;
  
  (* clobber sub-graph data stuff *)
  type data = data2;
  val empty_data = empty_data2;
  val get_data = get_data_of_hdata o G.get_data;
  val update_data = G.update_data o update_data_of_hdata;

  (* for bbox part of added data *)
  val get_unboxed = get_unboxed_of_hdata o G.get_data;
  val get_bboxes : T -> VBMap.T = get_bboxes_of_hdata o G.get_data;
  val get_bbox_list = VBMap.get_codlist o get_bboxes;
  val update_unboxed = G.update_data o update_unboxed_of_hdata;
  val update_bboxes = G.update_data o update_bboxes_of_hdata;
  val set_unboxed = update_unboxed o K;
  val add_to_unboxed = update_unboxed o V.NSet.add;
  val del_from_unboxed = update_unboxed o V.NSet.delete;
  val set_bboxes : VBMap.T -> T -> T = update_bboxes o K;
  val get_bbox = B.NTab.get o VBMap.get_codtab o get_bboxes;

  (* modified/new basic graph functions *)
  fun add_named_vertex n v g =
      let val (n2,g2) = G.add_named_vertex n v g
      in (n2, add_to_unboxed n2 g2) end;

  (* deleting vertex also removes all it's edges. *)
  fun delete_vertex n g = 
      g |> del_from_unboxed n
        |> update_bboxes (VBMap.surj_del_dom n)
        |> G.delete_vertex n;

  fun rename_vname n1 n2 g = 
      g |> G.rename_vname n1 n2
        (* the NONE case should never happen: all vertices already occur in 
           graph, so G.rename_vname should have raised an exeption. *)
        |> update_bboxes (the o VBMap.try_rename1_dom n1 n2) 
        |> update_unboxed (the o V.NSet.try_rename1 n1 n2); 
                       

  exception bname_already_exists_exp of B.name * T;

  (* raised bbname_already_exists_exp if bbox name already exists *)
  fun rename_bname n1 n2 g = 
      g |> update_bboxes (fn bxs => 
                             case VBMap.try_rename1_cod n1 n2 bxs 
                              of NONE => raise bname_already_exists_exp (n1,g)
                               | SOME bxs2 => bxs2);

  fun try_rename1_bname n1 n2 g = 
      (SOME (rename_bname n1 n2 g)) handle bname_already_exists_exp _ => NONE;

  (* prettifying *)
  fun pretty g = 
      Pretty.chunks 
        [ Pretty.str "BangBoxGraph{",
          Pretty.block 
            [Pretty.str "  ", (* indent *)
             Pretty.chunks 
               ((if VBMap.is_empty (get_bboxes g) then []
                 else [Pretty.block 
                         [Pretty.str "Bang-Boxes: ", 
                          VBMap.pretty (get_bboxes g)]])
                @ [G.pretty g])],
          Pretty.str "}"
        ];

  val print = Pretty.writeln o pretty;

end (* Functor BasicBangGraphFun : ... -> BASIC_BANG_GRAPH *)


(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-==-=-=-=-=-=-=-=-=-=- *) 
(*  functor make a BANG_GRAPH *)
(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-==-=-=-=-=-=-=-=-=-=- *) 
(* Given a BASIC_BANG_GRAPH, provide it with various tools *)
functor BangGraphTools(G : BASIC_BANG_GRAPH)
: BANG_GRAPH
= struct 

  (* provide basic bang-graph functions and sub-structures  *)
  open G;

  (* provide open graph functions/tools *)
  structure OGraph = OGraphFun(G);
  open OGraph;

  (* all !-box names *)
  val get_bbnames = VBMap.get_codset o get_bboxes;
  val add_to_bbnames = B.NSet.union_merge o get_bbnames;

  (* all vertices in a bbox *)
  val get_boxed = VBMap.get_domset o get_bboxes;

  structure BBoxCRnm = CompoundRenamingFun(
  struct 
    structure Nm = B
    type obj = T
    val try_rename1 = try_rename1_bname;
    val get_nameset = get_bbnames
  end);

  (*  *)
  fun rename_incl_bboxes (vrn,ern,brn) g = 
      let 
        val (vrn2,g') = VertexCRnm.rename vrn g
        val (ern2,g'') = EdgeCRnm.rename ern g'
        val (brn2,g''') = BBoxCRnm.rename brn g''
      in ((vrn2,ern2,brn2),g''') end;
  
  (* rename g2 apart from g1 *)
  fun rename_apart_incl_bboxes g1 g2 = 
      let 
        val vrn = V.Rnm.mk_from_avoids (get_vnames g1)
        val ern = E.Rnm.mk_from_avoids (get_enames g1)
        val brn = B.Rnm.mk_from_avoids (get_bbnames g1)
      in rename_incl_bboxes (vrn,ern,brn) g2 end;



  exception overlapping_bbox_exp of V.NSet.T * T;
  exception no_such_bbox_exp of unit;

  (* lookup name of box that v is in, NONE if unboxed *)
  fun lookup_box_of g v = VBMap.lookup_domf (get_bboxes g) v;
  fun get_box_of g v = 
      VBMap.domf (get_bboxes g) v 
      handle VBMap.not_in_dom_exp _ => raise no_such_bbox_exp ();

  fun is_boxed g v = V.NSet.contains (VBMap.get_domset (get_bboxes g)) v;

  val has_bname = B.NTab.contains_name o VBMap.get_codtab o get_bboxes;

  (* make a new empty !-box *)
  fun new_box bn g = 
      let
        val bboxes = (get_bboxes g);
        val bn2 = B.NSet.new (VBMap.get_codset bboxes) bn;
        val bboxes2 : VBMap.T = 
            VBMap.add_to_cod bn2 V.NSet.empty bboxes;
      in (bn2, g |> set_bboxes bboxes2) end;
  
  (* add to a !-box; makes new box, if name doesn't alreayd exist;
  IMPROVE: raise exception if box doesn't already exist? *)
  fun move_to_box bn vs g = 
      g |> update_bboxes (VBMap.add_to_cod bn vs 
                          o V.NSet.fold VBMap.del_dom vs)
        |> update_unboxed (V.NSet.remove_set vs);
  
  fun move_to_unbox vs g = 
      g |> update_bboxes (V.NSet.fold VBMap.del_dom vs)
        |> update_unboxed (V.NSet.union_merge vs);
  
  (* overrides previous function *)
  (* Merge g1 into g2.
     (Replaces basic merge_by_vertices to include bboxes) 
     Assumes edge-names are disjoint. Assumes bbox names disjoint. 
     Assumes all edge-points from g1 are in g2 already (and copied bboxes skip edge-points)
     When an edge-point in g1 overlaps an internal vertex in g2, if the
     edge-point is in a bangbox, then the bang-box doesn't extend to the
     internal vertex. *)
  fun merge_by_vertices g1 g2 =
      let val g1bboxes = get_bboxes g1
      in
        g2 |> OGraph.merge_by_vertices g1
           |> B.NTab.fold
                (fn (bbn,vset) => 
                  move_to_box bbn 
                    (V.NSet.subtract vset (get_edgepoints g1)))
                (VBMap.get_codtab g1bboxes)
       end;

  (* copy bang box, given renaming info, or possibly with dictated renaming. *)
  fun copy1_box bn ((vrn,ern,brn),g) = 
      let val bbox_vs = get_bbox g bn;
          val old_new_vnames = V.Rnm.get_newnames vrn;
          val vrn2 = V.Rnm.set_newnames V.NSet.empty vrn;
          val ((vrn3,ern'),g') = copy1_vset bbox_vs ((vrn2, ern),g);
          val (new_bn_opt,brn') = B.Rnm.rename1 bn brn;
          val bn' = (case new_bn_opt of NONE => bn | SOME bn' => bn'); 
          val new_vs = V.Rnm.get_newnames vrn3;
          val vrn' = V.Rnm.set_newnames 
                       (V.NSet.union_merge new_vs old_new_vnames) vrn3
      in
         (bn',
          ((vrn',ern',brn'), (* copying information *)
           update_bboxes (VBMap.add_to_cod bn' new_vs) g' (* new graph *)
         ))
      end;

  fun fresh_copy1_box bn g = 
      let val (bname, (_, graph)) = copy1_box bn
                ((V.Rnm.mk_from_avoids (get_vnames g),
                E.Rnm.mk_from_avoids (get_enames g),
                B.Rnm.mk_from_avoids (get_bbnames g)),g)
      in (bname, graph) end;
  
  fun kill_box bn g = 
      let val bbox_vs = get_bbox g bn
      in g |> V.NSet.fold delete_vertex bbox_vs
           |> update_bboxes (VBMap.del_cod bn)
      end;
  
  fun drop_box bn g = 
      let val bbox_vs = get_bbox g bn 
      in g |> update_bboxes (VBMap.del_cod bn)
           |> update_unboxed (V.NSet.union_merge bbox_vs)
      end;
  
  
  (* *)
  exception merge_bbox_exp of string 
  
  (* returns bbox-name merged all boxes into and new merged graph *)
  fun merge_boxes bnset g = 
      (case B.NSet.pull_local_top bnset of 
         NONE => raise merge_bbox_exp "given empty bbox name set"
       | SOME (bn,bnset2) => 
         (bn, B.NSet.fold 
              (fn bn2 => fn g2 =>
                   g2 |> move_to_box bn (get_bbox g2 bn2)
                      |> update_bboxes (VBMap.del_cod bn2))
              bnset2 g));
  
  
  (* FIXME: this code is largely duplicated in bgraph - clean up *)
  
  (* IMPROVE: move these into graph *)
  fun pair_from_of_edge g e = 
      let val ((bd,ed),(from,to)) = get_edge g e in (e,ed,from) end;
  fun pair_to_of_edge g e = 
      let val ((bd,ed),(from,to)) = get_edge g e in (e,ed,to) end;
  
  (* auxillary function; adding a vertex to a map of adj banged, 
     or a set of others. *)
  fun add_to_others g n (vtobang, others) = 
      (case lookup_box_of g n of NONE => (vtobang, V.NSet.add n others)
       | SOME bbn => (if VBMap.dom_contains vtobang n then vtobang 
                         else VBMap.add_to_dom n bbn vtobang, 
                      others));
  
  (* find all adjacent vertices, except self, divided into: 
     boundary leafs, bangbox vertices, and others *)
  fun adj_tgt_info_bangs' g n0 (d,(ins,outs)) = 
      let 
        fun consider_edge (e,ed,n) (loopes, others) = 
            if V.name_eq (n,n0) then (E.NTab.update (e, ed) loopes, others)
            else (loopes, add_to_others g n others)
      in 
        (d, (E.NTab.empty, (VBMap.empty, V.NSet.empty))
              |> (E.NSet.fold (consider_edge o (pair_from_of_edge g)) ins)
              |> (E.NSet.fold (consider_edge o (pair_to_of_edge g)) outs))
      end;
  
  fun adj_tgt_info_bangs g n =  adj_tgt_info_bangs' g n (get_vertex g n);
  
  (* find all adjacent vertices, except self, divided into: 
     boundary leafs, and others *)
  fun adj_pat_info_bangs' g n0 (d,(ins,outs)) = 
      let 
        fun consider_edge eh (leaftab, loopes, others) = 
            let val n = get_ehn_vname g (H.other eh) 
                val en = H.get_ename eh in
            if V.name_eq (n,n0) then (* self-loop *)
              (leaftab, E.NTab.update (en,get_edge_data g en) loopes, others)
            else if V.NTab.contains leaftab n then 
              (V.NTab.delete n leaftab, loopes, add_to_others g n others)
            else if is_boundary g n then 
              (V.NTab.ins (n,(eh,get_edge_data g en)) leaftab, loopes, others)
            else (leaftab, loopes, add_to_others g n others)
            end;
      in 
        (d, (V.NTab.empty, E.NTab.empty, (VBMap.empty, V.NSet.empty))
              |> (E.NSet.fold (consider_edge o H.mk_end) ins)
              |> (E.NSet.fold (consider_edge o H.mk_start) outs))
      end;
  
  fun adj_pat_info_bangs g n = adj_pat_info_bangs' g n (get_vertex g n);

  (* get arrities to adjacent vertices, return two tables, one for normal edges 
     and one for those in a different bang-boxes. Filter by function: when function is true, skip this adj entry. *)
  fun get_filtered_adj_arities_and_bang_arities f g n = 
      let 
        val nbbox = lookup_box_of g n;
  
        (* interesting case for auto-optimisation *)
        fun in_a_different_bbox n2 = 
            (case nbbox of NONE => lookup_box_of g n2
             | SOME bbn => 
                (case lookup_box_of g n2 of 
                    NONE => NONE
                  | SOME bbn2 => 
                    if (not (B.name_eq (bbn, bbn2))) 
                    then SOME bbn2 else NONE));
  
        (* *)
        fun init_adj_info (eh,(UnDirected,ed)) =  
            Arity.add_1_undir Arity.zero
          | init_adj_info (eh,(Directed,ed)) = 
            if H.is_start eh then Arity.add_1_in Arity.zero
            else Arity.add_1_out Arity.zero;
        (* *)
        fun add_one_to_adj_info (eh,(UnDirected,ed)) a = Arity.add_1_undir a
          | add_one_to_adj_info (eh,(Directed,ed)) a =
            if H.is_start eh then Arity.add_1_in a
            else Arity.add_1_out a;

        fun add_one_arity e n2 ntab =
            if V.NTab.contains_name ntab n2 then
              V.NTab.map_entry (add_one_to_adj_info e) n2 ntab
            else V.NTab.update (n2,init_adj_info e) ntab;
  
        fun consider1 e n2 (ntab,bboxntab) = 
            if f (e,n2) then (ntab,bboxntab) else 
            (case in_a_different_bbox n2 of 
               NONE => (add_one_arity e n2 ntab, bboxntab)
             | SOME bbn =>  
               (ntab,
                if B.NTab.contains_name bboxntab bbn then
                  B.NTab.map_entry (add_one_arity e n2) bbn bboxntab
                else 
                  B.NTab.update (bbn, add_one_arity e n2
                                           V.NTab.empty) 
                                   bboxntab))
      in 
        fold_adj consider1 g n (V.NTab.empty, B.NTab.empty)
      end;
  
  (* get arrities to adjacent vertices, return two tables, one for normal edges 
     and one for those in a different bang-boxes. *)
  val get_adj_arities_and_bang_arities = 
      get_filtered_adj_arities_and_bang_arities (K false);

end; (* BangGraphFun *)

(* vim:et:sts=2:sw=2
*)
