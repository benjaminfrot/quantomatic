(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-==-=-=-=-=-=-=-=-=-=- *) 
(*  Representation for Open Graphs *)
(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-==-=-=-=-=-=-=-=-=-=- *) 
(*  Graphs with Boundary *)
(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-==-=-=-=-=-=-=-=-=-=- *) 
signature OGRAPH_SHARING = 
sig 
include BASIC_GRAPH_SHARING;
structure OVData : OVERTEX_DATA_SHARING;
sharing VData = OVData;
end;

(* Basic open graph *)
signature BASIC_OGRAPH = 
sig
include BASIC_GRAPH
structure OVData : OVERTEX_DATA
sharing VData.Sharing = OVData.Sharing
structure SharingOGraph : OGRAPH_SHARING
sharing SharingBasicGraph = SharingOGraph
sharing SharingOGraph.OVData = OVData.SharingWithIData

(* points (edge and boundary, both kinds of vertices) 
   have no data. Boundary have only input edges, 
   or only output edges. Edgepoints have both input and output edges *)

(* boundaries represent end of a half-edge.  *)
val get_boundary : T -> V.NSet.T
val is_boundary : T -> V.name -> bool

(* edge points; parts of an edge *)
val get_edgepoints : T -> V.NSet.T
val is_edgepoint : T -> V.name -> bool
val is_endpoint' : OVData.data * (E.NSet.T * E.NSet.T) -> bool
(* returns the SOME non-empty edge set when exactly one of the inset of ourset of edges is empty, 
   else NONE *)
val endpoint_of_vertex' : OVData.data * (E.NSet.T * E.NSet.T) 
    -> (H.halfid * E.NSet.T) option

(* internal: don't presurve well-formedness *)
val add_to_boundary : V.name -> T -> T
val add_to_edgepoints : V.name -> T -> T
val del_from_boundary : V.name -> T -> T
val del_from_edgepoints : V.name -> T -> T
val update_boundary : (V.NSet.T -> V.NSet.T) -> T -> T
val update_edgepoints : (V.NSet.T -> V.NSet.T) -> T -> T

end; (* Basic OGraph *)


(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-==-=-=-=-=-=-=-=-=-=- *) 
(*  Extra stuff for open graphs (cut out subgraph etc.) *)
(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-==-=-=-=-=-=-=-=-=-=- *) 
signature OGRAPH = 
sig 
include GRAPH
(* include BASIC_OGRAPH *** FIXME: fix ML: should be able to include union of signatures. Without it, we copy/paste code from BASIC_OGRAPH... *)
structure OVData : OVERTEX_DATA
sharing VData.Sharing = OVData.Sharing
structure SharingOGraph : OGRAPH_SHARING
sharing SharingBasicGraph = SharingOGraph
sharing SharingOGraph.OVData = OVData.SharingWithIData

(* points (edge and boundary, both kinds of vertices) 
   have no data. Boundary have only input edges, 
   or only output edges. Edgepoints have both input and output edges *)

(* boundaries represent end of a half-edge.  *)
val get_boundary : T -> V.NSet.T
val is_boundary : T -> V.name -> bool

(* given two vertices, check if they are boundary-coherent end-points and return 
   data for a compatible edge that could replace them. *)
val boundary_coherence : T -> V.name -> V.name -> 
     ((dir_or_undir * EData.data) * (V.name * V.name)) option

(* adjacent boundary fns *)
val get_adj_boundary : T -> V.name -> V.NSet.T
val get_adj_inputs : T -> V.name -> V.NSet.T
val get_adj_outputs : T -> V.name -> V.NSet.T

(* edge points; parts of an edge *)
val get_edgepoints : T -> V.NSet.T
val is_edgepoint : T -> V.name -> bool
val is_endpoint' : OVData.data * (E.NSet.T * E.NSet.T) -> bool
(* returns the SOME non-empty edge set when exactly one of the inset of 
   ourset of edges is empty, 
   else NONE *)
val endpoint_of_vertex' : OVData.data * (E.NSet.T * E.NSet.T) 
    -> (H.halfid * E.NSet.T) option;

(* internal: don't presurve well-formedness *)
val add_to_boundary : V.name -> T -> T
val add_to_edgepoints : V.name -> T -> T
val del_from_boundary : V.name -> T -> T
val del_from_edgepoints : V.name -> T -> T
val update_boundary : (V.NSet.T -> V.NSet.T) -> T -> T
val update_edgepoints : (V.NSet.T -> V.NSet.T) -> T -> T


(* *** END OF COPIED SIGNATURE *** *)

(* plug together two boundary-coherent edge points. In the process, this function creates an edge, and
   returns ((source, target), (edge, new graph)) *)
val plug_by_boundary : V.name -> V.name -> T -> (V.name * V.name) * (E.name * T)


val is_boundary_edge : T -> E.name -> bool

(* get points living on an edge; but not boundary ones *)
val get_edgepoint_vnames : T -> V.NSet.T

(* get the subsets of boundary, divided into either input or output. *)
val get_in_and_out_vnames : T -> V.NSet.T (* input *) 
                                 * V.NSet.T (* output *)

(* change vertex into a point (throw away data, making this an edge-point or a boundary point) *)
val change_into_edgepoint : V.name -> T -> T
val change_into_internal : V.name -> OVData.IData.data -> T -> T

(* merge points (all adj edges) and keep vertex data (replacing edge-point), assumes they have the same internal data if they are both internal vertices *)
val rename_or_merge_vname : V.name -> V.name -> T -> T

(* cut all edges that go outside the selected set of vertices from the 
   given vertex. Extends the gluing automorphism *)
val cut_around_vertex : V.NSet.T -> V.name 
    -> (VInjEndo.T * T) -> (VInjEndo.T * T)
(* cut all edges that go from within the subgraph to outside it; 
   returns the gluing automorphism, and a new graph which will be disjoint *)
val cut_around_subgraph: V.NSet.T -> T -> (VInjEndo.T * T)

(* Given selection set of vertices, make subgraph with with incident edges that 
   went to a vertex outside selection, now go to a single edge-point. Perserves 
   matching; doesn't (necessarily) produce a valid ograph. *)
val matched_subgraph_within_vset' : V.NSet.T -> T 
    -> VInjEndo.T * T (* returns gluing/cutting for new 'boundary', 
                              and cut graph *)
val matched_subgraph_within_vset : V.NSet.T -> T -> T

(* Given selection set of vertices, make subgraph: 
   all incident edges to selection are removed; Like copy in a graphics program *)
val delete_subgraph_outside_vset : V.NSet.T -> T -> T

 
(* 
val adj_tgt_info : 
    T -> V.name 
    -> VData.data 
       * (EData.data E.NTab.T (* directed self-loops *)
          * EData.data E.NTab.T (* undireted self-loops *)
          * V.NSet.T) (* other adj vertices *)
*)

(* adjacent information next to an edge *)
(* datatype adj_info = 
  AdjInfo of { undir_bndry : (H.name * EData.data) V.NTab.T,
               in_bndry : (H.name * EData.data) V.NTab.T,
               out_bndry : (H.name * EData.data) V.NTab.T,
               dir_loops : EData.data E.NTab.T,
               undir_loops : EData.data E.NTab.T,
               other_vs : V.NSet.T
             };

val adj_info : 
    T -> V.name 
    -> VData.data 
       * ((H.name * EData.data) V.NTab.T (* undirected boundary *)
          * (H.name * EData.data) V.NTab.T (* incoming boundary *)  
          * (H.name * EData.data) V.NTab.T (* outgoing boundary *)
          * EData.data E.NTab.T (* direted self-loops *)
          * EData.data E.NTab.T (* undirected self-loops *)
          * V.NSet.T) (* other adj vertices *)
*)

end;


(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-==-=-=-=-=-=-=-=-=-=- *) 
(*  Basic Open Graph (Graph with a boundary/edge-points) *)
(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-==-=-=-=-=-=-=-=-=-=- *) 
functor BasicOGraphFun(
(*         structure OVData : OVERTEX *)
        structure Param : OGRAPH_PARAM
        (* sharing Param.VData.SharingWithData = OVData.SharingWithData *)
        type data (* graph additional extensible/hidden data *)
        val empty_data : data
) 
: BASIC_OGRAPH
= struct
  structure InParam = Param;
  
  (* to avoid using clobbered data and empty graph from the 
     open G (see below) *)
  type data2 = data;
  val empty_data2 = empty_data;
  
  (* we add boundary to Graph data, as well as edge-points; these are 
     disjoint sets *)
  type hdata = { boundary : V.NSet.T,
                 edgepoints : V.NSet.T,
                 data : data};
  val empty_hdata = {boundary = V.NSet.empty,
                     edgepoints = V.NSet.empty,
                     data = empty_data};
  fun get_data_of_hdata hdata = #data hdata;
  fun update_data_of_hdata f hdata = 
      {boundary = #boundary hdata, 
       edgepoints = (#edgepoints hdata),
       data = f (#data hdata)};
  fun get_boundary_of_hdata hdata = #boundary hdata;
  fun update_boundary_of_hdata f hdata = 
      {boundary = f (#boundary hdata), 
       edgepoints = (#edgepoints hdata),
       data = (#data hdata)};    
  fun get_edgepoints_of_hdata hdata = #edgepoints hdata;
  fun update_edgepoints_of_hdata f hdata = 
      {boundary = (#boundary hdata), 
       edgepoints = f (#edgepoints hdata),
       data = (#data hdata)};    

  (* make basic graph with this as internal data *)
  structure G = BasicGraphFun(
    structure Param = Param;
    type data = hdata
    val empty_data = empty_hdata
  );
  (* inherit functions from Graph *)
  open G;
  structure Param = InParam;
  structure OVData = Param.OVData;
  structure VData = OVData;
  structure EData = Param.EData;
  
  (* clobber sub-graph data *)
  type data = data2;
  val empty_data = empty_data2;
  val get_data = get_data_of_hdata o G.get_data;
  val update_data = G.update_data o update_data_of_hdata;

  (* for boundary part of added data *)
  val get_boundary = get_boundary_of_hdata o G.get_data;
  val update_boundary = G.update_data o update_boundary_of_hdata;
  val set_boundary = update_boundary o K;
  (* for edgepoints *)
  val get_edgepoints = get_edgepoints_of_hdata o G.get_data;
  val update_edgepoints = G.update_data o update_edgepoints_of_hdata;
  val set_edgepoints = update_edgepoints o K;

  (* *)
  val add_to_boundary = update_boundary o V.NSet.add;
  val del_from_boundary = update_boundary o V.NSet.delete;
  val is_boundary = V.NSet.contains o get_boundary;

  (* endpoints are edge-points with ins or outs empty. *)
  fun endpoint_of_vertex' (OVData.EVert,(ins,outs)) =
      (case (E.NSet.is_empty ins, E.NSet.is_empty outs) of
         (true, true) => NONE
       | (true,false) => SOME (H.SourceEnd, outs)
       | (false,true) => SOME (H.TargetEnd, ins)
       | (false,false) => NONE)
    | endpoint_of_vertex' (OVData.IVert d,(ins,outs)) = NONE;
  
  val is_endpoint' = is_some o endpoint_of_vertex';
  val is_edgepoint = V.NSet.contains o get_edgepoints;
  val add_to_edgepoints = update_edgepoints o V.NSet.add;
  val del_from_edgepoints = update_edgepoints o V.NSet.delete;

  (* implicit: g *)
  fun rename1_in_boundary n1 n2 = 
      update_boundary (fn bs => 
                          case V.NSet.try_rename1 n1 n2 bs
                           of NONE => bs
                            | SOME bs2 => bs2);

  (* implicit: g *)
  fun rename1_in_edgepoints n1 n2 = 
      update_edgepoints (fn vs => 
                          case V.NSet.try_rename1 n1 n2 vs
                           of NONE => vs
                            | SOME vs2 => vs2);


  (* modified/new basic graph functions *)
  fun add_named_vertex n v g =
      let val (n2,g2) = G.add_named_vertex n v g
      in (n2, g2 |> (case v of (OVData.EVert) => add_to_edgepoints n2 
                             | (OVData.IVert _) => I))
      end;
  (* Note: deleting vertex also removes all it's edges. *)
  fun delete_vertex n g = 
      g |> del_from_boundary n (* if not in boundary, does nothing *)
        |> del_from_edgepoints n (* if not in edgepoints, does nothing *)
        |> G.delete_vertex n;

  (* *)
  fun update_point_kind_from_del_edge n g = 
      let val (d,(ins,outs)) = V.NTab.get (get_vertices g) n in
        case d of 
          OVData.IVert _ => g
        | OVData.EVert => 
          (case (E.NSet.is_empty ins, E.NSet.is_empty outs) of
             (true, true) => g |> del_from_boundary n (* became isolated *)
           | (false,true) => g |> add_to_boundary n
           | (true,false) => g |> add_to_boundary n
           | (false,false) => g (* had many incident edges *))
      end;

  (* *)
  fun update_point_kind_from_add_edge n g = 
      let val (d,(ins,outs)) = V.NTab.get (get_vertices g) n in
        case d of 
          OVData.IVert _ => g
        | OVData.EVert => 
          (case (E.NSet.is_empty ins, E.NSet.is_empty outs) of
             (* has both incoming and outgoing egdes, so not boundary. *)
             (false, false) => g |> del_from_boundary n |> add_to_edgepoints n
           | (_,_) => g |> add_to_boundary n)
      end;

  (* *)
  fun add_named_edge en e n1 n2 g = 
      let val (en2,g2) = G.add_named_edge en e n1 n2 g in 
        (en2, 
         g2 |> update_point_kind_from_add_edge n1 
            |> update_point_kind_from_add_edge n2)
      end;

  fun delete_edge en g = 
      let val (e,(fromv,tov)) = E.NTab.get (get_edges g) en in
        g |> G.delete_edge en
          |> update_point_kind_from_del_edge fromv
          |> update_point_kind_from_del_edge tov
      end;

  (* vname = suggested name *)
  (* rename all occurances of old name (1st arg) with new name (2nd arg) 
     n2 must not exist already, n1 must exist 
     raises 
  *)
  fun rename_vname n1 n2 g = 
      g |> rename1_in_boundary n1 n2
        |> rename1_in_edgepoints n1 n2 
        |> G.rename_vname n1 n2;

  (* prettifying *)
  fun pretty g = 
      Pretty.chunks 
        [ Pretty.str "OGraph{",
          Pretty.block 
            [Pretty.str "  ", (* indent *)
             Pretty.chunks 
               [Pretty.block 
                  [Pretty.str "Boundary Vertices: ",
                   Pretty.list "{" "}" 
                               (map V.pretty_name (V.NSet.list_of (get_boundary g)))],
                G.pretty g]],
          Pretty.str "}"
        ];
      
  val print = Pretty.writeln o pretty;
  
  structure SharingOGraph = 
    struct
      open SharingBasicGraph;
      structure OVData = OVData.SharingWithIData;
    end;

end; (* structure BasicOGraph *)



(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-==-=-=-=-=-=-=-=-=-=- *) 
(*  Extra stuff for open graphs (cut out subgraph etc.) *)
(* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-==-=-=-=-=-=-=-=-=-=- *) 
functor OGraphFun(G : BASIC_OGRAPH)
(* : OGRAPH *) 
= struct
  open G;
  
  structure GraphTools = GraphToolsFun(G);
  open GraphTools;
  
  (* change n to become a boundary vertex *)
  fun change_into_edgepoint n g = 
      g |> (if is_endpoint' (get_vertex g n)
            then add_to_boundary else add_to_edgepoints) n
        |> set_vertex_data OVData.EVert n;
  
  (* change n to become a boundary vertex *)
  fun change_into_internal n d g = 
      g |> del_from_boundary n
        |> del_from_edgepoints n
        |> set_vertex_data (OVData.IVert d) n;
  
  (* cut an edge, adding the introduced bounary vertices to the automorphism *)
  fun cut_edge' (e,(d,(fromv,tov))) g = 
      let val (newv1,g1) = add_vertex OVData.EVert g 
          val (newv2,g2) = add_vertex OVData.EVert g1
          val (newe,g3) = add_edge d fromv newv2 g2
      in
        (((e,newv2),(newe,newv1)),
         g3 |> update_edges (E.NTab.update (e, (d,(newv1,tov))))
            |> add_to_boundary newv1 
            |> add_to_boundary newv2)
      end;

  fun cut_edge e g = 
      let val (d,(fromv,tov)) = get_edge g e 
      in cut_edge' (e, get_edge g e) g end;

  (* v1 and v2 are boundary coherent (half-edges of opposite direction, or both undirected): they can be plugged together; return SOME ((fromv,tov),(dir,edgedata)) where fromv is the source of connecting edge, and tov is the target. If the half-edges were directed, this respects the edge direction. 
  Assumes edge data is the same for both edges. 
  *)
  fun boundary_coherence g v1 v2 = 
      (case endpoint_of_vertex' (get_vertex g v1) of 
         NONE => NONE
       | SOME (halfid1,es1) => 
         (case endpoint_of_vertex' (get_vertex g v2) of 
            NONE => NONE
          | SOME (halfid2,es2) => 
            (case (E.NSet.tryget_singleton es1, 
                   E.NSet.tryget_singleton es2) of 
               (SOME e1,SOME e2) => 
               let val ((dir_or_undir1,ed1),(fromv1,tov1)) = get_edge g e1
                   val ((dir_or_undir2,ed2),(fromv2,tov2)) = get_edge g e2
               in 
                  if dir_or_undir1 = Directed andalso dir_or_undir2 = Directed
                     andalso halfid1 <> halfid2 then 
                    SOME ((dir_or_undir1, ed1),
                          if halfid1 = H.SourceEnd then (fromv2,tov1) 
                          else (fromv1,tov2))
                  else if dir_or_undir1 = UnDirected 
                       andalso dir_or_undir2 = UnDirected then 
                    SOME ((dir_or_undir1, ed1),
                          (if halfid1 = H.SourceEnd then tov1 
                           else fromv1, 
                           if halfid2 = H.SourceEnd then tov2 
                           else fromv2))
                  else NONE
               end
             | (_,_) => NONE)));

  val boundary_coherent = is_some ooo boundary_coherence;
(* 
      (case endpoint_of_vertex' (get_vertex g v1) of 
         NONE => NONE
       | SOME (halfid1,es1) => 
         (case endpoint_of_vertex' (get_vertex g v2) of 
            NONE => NONE
          | SOME (halfid2,es2) => 
            (case (E.NSet.tryget_singleton es1, 
                   E.NSet.tryget_singleton es2) of 
               (SOME e1,SOME e2) => 
               let val (dir_or_undir1,(ed1,(fromv1,tov1))) = get_edge g e1
                   val (dir_or_undir2,(ed2,(fromv2,tov2))) = get_edge g e2
                   val (src, dst) = if V.name_eq (fromv1, v1) 
                                      then ((fromv2,e2), (tov1,e1)) 
                                      else ((fromv1,e1), (tov2,e2)); 
               in 
                  if dir_or_undir1 = Directed andalso dir_or_undir2 = Directed
                       andalso halfid1 <> halfid2 then 
                     SOME (Directed, (src, dst))
                  else if dir_or_undir1 = UnDirected 
                       andalso dir_or_undir2 = UnDirected then 
                     SOME (UnDirected, (src, dst))
                  else NONE
               end)
             | (_,_) => NONE));
*)


  (* plug two half-edges, represented by vertices. This is equiavlent to graph 
     composition with an identity. Assumes that e1 and e2 go to boundary 
     coherent edge-point vertices (vertices representing half-edges going in 
     opposite directions / both undirected) *)
  (* FIXME(ldixon): *** needs modification for !-boxes *** *) 
  exception not_boundary_coherent_exp of string;

  fun plug_by_boundary v1 v2 g = 
      (case boundary_coherence g v1 v2 
        of NONE => raise not_boundary_coherent_exp "plug_by_boundary"
         | SOME ((dir, data),(startv,endv)) => 
           ((startv,endv),
            g |> delete_vertex v1
              |> delete_vertex v2
              |> add_edge (dir, data) startv endv));


  (* Cut edges around a vertex if they are not in the keepvset; change cut 
     incident edges into half-edges (add a boundary vertex to each one). 
     Creates V.InjEndo.T which explains how to glue cut back together; 
     automorphism is of the form: keepvset vertex => outside vertex.  
     NOT** INVARIANT: preserves names of the keepset, creates new 
     edges/boundary vertices for the rest of the graph. 
  *)
  (* FIXME: rewrite using fold_subgraph (from graph), with cut_edge (above) *)
  fun cut_around_vertex keepvset n (vs_g as (amorph,g)) = 
      (case get_vertex g n of (OVData.EVert,(ins,outs)) => vs_g
       | (d,(ins,outs)) => 
         vs_g
          |> E.NSet.fold 
              (fn e => fn (newvs,g) => 
                let val (d,(fromv,tov)) = get_edge g e in 
                  if V.NSet.contains keepvset fromv then (newvs, g)
                  else
                    let val (newv1,g1) = add_vertex OVData.EVert g 
                        val (newv2,g2) = add_vertex OVData.EVert g1
                        val (newe,g3) = add_edge d fromv newv2 g2
                    in
                      (amorph |> VInjEndo.add newv1 newv2,
                       g3 |> update_edges (E.NTab.update (e, (d,(newv1,n))))
                          |> add_to_boundary newv1)
                    end
                end)
              ins 
          |> E.NSet.fold 
              (fn e => fn (newvs,g) => 
                let val (d,(fromv,tov)) = get_edge g e in 
                  if V.NSet.contains keepvset tov then (newvs, g)
                  else
                    let val (newv1,g1) = add_vertex OVData.EVert g 
                        val (newv2,g2) = add_vertex OVData.EVert g1
                        val (newe,g3) = add_edge d newv2 tov g2
                    in
                      (amorph |> VInjEndo.add newv1 newv2,
                       g3 |> update_edges (E.NTab.update (e, (d,(n,newv1))))
                          |> add_to_boundary newv1)
                    end
                end)
              outs);
    
  (* Property to be checked -- all boundary vertices have degree one *)
  (* This is not maintained but can be checked with the is_correct function*) 
  (* in particular, the graph formalism allows hyper-edges 
     (internal points that branch) *)
  fun is_vertex_concrete_correct g n = 
      if is_boundary g n then
        let val (_,(ins,outs)) = (get_vertex g n) in
          (E.NSet.is_empty ins andalso E.NSet.is_singleton outs) 
          orelse
          (E.NSet.is_empty outs andalso E.NSet.is_singleton ins) 
        end
      else true
  fun is_concrete_correct g = 
      V.NSet.fold (fn n => fn b => (is_vertex_concrete_correct g n) 
                                   andalso b)  
                  (get_boundary g)
                  true;
  
  (* if n1 is boundary and something else is already called n2, then
  merge n1 and the vertex called n2, used for bang-box copy *)
  
  (* rename n1 to n2, if n2 already exists, if several vertices have
     non-boundary data, its assumed to be the same. 
     edges; get unioned
     Note: I've not really thought about what happens if n1 = n2, currently id. 
  *)
  fun rename_or_merge_vname n1 n2 bg =
      if V.name_eq (n1,n2) then bg (* should raise an error? *)
      else 
      (case lookup_vertex bg n2 
        of NONE => bg |> rename_vname n1 n2
         | SOME (d2,(ins2,outs2)) => (* clash, so merge egdes to n1 into n2 *)
           let val (d1,(ins1,outs1)) = get_vertex bg n1
           in
             bg |> (case d1 
                     of OVData.EVert => update_boundary (V.NSet.delete n1)
                      | OVData.IVert id2 => 
                        (case d2 
                          of OVData.EVert => (* update boundary and data *)
                             update_boundary (V.NSet.delete n2)
                             o set_vertex_data d1 n2
                           | OVData.IVert id1 => I)) (* nothing to do *)
                (* update edges *)
                |> E.NSet.fold (update_edge_vnames 
                                     (fn (from,to) => (from,n2))) ins1 
                |> E.NSet.fold (update_edge_vnames 
                                     (fn (from,to) => (n2,to))) outs1 
                |> update_vertex_enames (K (E.NSet.union_merge ins1 ins2,
                                            E.NSet.union_merge outs1 outs2)) n2
                (* drop boundary node n1; keep what it was merged with *)
                |> update_vertices (V.NTab.delete n1)
           end);
  
  (* cut around subgraph identified by vns; introduces new half-edges, so that 
     vns is disjoint from the rest of the graphs. *)
  fun cut_around_subgraph vns g = 
      V.NSet.fold 
        (cut_around_vertex vns)
        vns
        (VInjEndo.empty,g);
  

  (* remove any vertices that don't have an edge from the vset and for any vertices not in vset, but with edge(s) to vset, they get changed into edge-points. Note: this is a cheeky use of edge-points for variable-vertices. We should probably introduce a proper notion of variable vertex/uninstantiated vertex. *)
  fun abstract_subgraph_from_vset vset (pvs_g as (pvs,g)) = 
      E.NTab.fold 
        (fn (e,((dir_or_undir,ed),(fromv,tov))) => fn (pvs_g as (pvs,g)) =>  
          case (V.NSet.contains vset fromv, V.NSet.contains vset tov) 
            of (true,true) => pvs_g
             | (false,true) => (V.NSet.add fromv pvs, change_into_edgepoint fromv g)
             | (true,false) => (V.NSet.add tov pvs, change_into_edgepoint fromv g)
             | (false,false) => pvs_g
        )
        (get_edges g)
        pvs_g;


  (* make a subgraph from a node selection: any vertices with edges
     outside selection become boundary, and all non-selected vertices are 
     deleted. Perserves matching.  *)
  fun matched_subgraph_within_vset' vns g = 
      cut_around_subgraph vns g
      |> (fn (amorph,g') => 
          (amorph, 
           g' |> V.NSet.fold delete_vertex (V.NSet.subtract (get_vnames g) vns)
              |> V.NSet.fold delete_vertex (VInjEndo.get_codset amorph)))
  
  (* as above, but ignores gluing automorphism (introduced boundary => old vs) *)
  val matched_subgraph_within_vset = 
      snd oo matched_subgraph_within_vset';
  
  
  (* make a subgraph from a node selection: any vertices with edges
     outside selection are deleted. NOTE: does not preserve type/Matching. 
     This is the usual graphics package form of "copying" a selected graph.
     (do we want this? or should we do a copy by cutting edges and throwing away 
      stuff outside the cut selection?)
  *)
  fun delete_subgraph_outside_vset vns g = 
      V.NSet.fold 
        (fn n => fn g => if V.NSet.contains vns n then g 
                         else delete_vertex n g)
        (get_vnames g) g;
  
  fun is_input_vertex' (OVData.EVert,(ins,_)) = E.NSet.is_empty ins
    | is_input_vertex' (OVData.IVert d,_) = false;
  fun is_output_vertex' (OVData.EVert,(_,outs)) = E.NSet.is_empty outs
    | is_output_vertex' (OVData.IVert d,_) = false;
  
  (* boundary vertex has either empty ins or empty outs. *)
  fun is_boundary_vertex' v = is_input_vertex' v orelse is_output_vertex' v;
  
  (* implicit: g n *)
  val is_boundary_vertex = is_boundary_vertex' oo get_vertex;
  val is_input_vertex = is_input_vertex' oo get_vertex;
  val is_output_vertex = is_output_vertex' oo get_vertex;
  
  (* goes to or comes from bounary vertex *)
  fun is_boundary_edge g e = 
      let val (d,(s,t)) = get_edge g e 
      in is_boundary_vertex g s orelse is_boundary_vertex g t end;
  
  fun get_edgepoint_vnames g = 
      V.NTab.fold 
        (fn (n,dio) => 
            if is_boundary_vertex' dio then V.NSet.add n
            else I)
        (get_vertices g)
        V.NSet.empty;
  
  (* identify in and out boundary nodes (all edges come in-to or
     out-of this node) and try to preserve them in rhs *)
  fun get_in_and_out_vnames g = 
      V.NSet.fold 
        (fn n => 
         fn (invs,outvs) => 
            let val (_,(ins,outs)) = get_vertex g n
            in
              if E.NSet.is_empty outs then 
                (invs, V.NSet.add n outvs)
              else if E.NSet.is_empty ins then 
                (V.NSet.add n invs, outvs) 
              else (invs,outvs)
            end)
        (get_boundary g)
        (V.NSet.empty, V.NSet.empty);
  
  
  (* get adjacent boundary vertices *)
  fun get_adj_boundary g n = filtered_adj_vnames (is_boundary_vertex g) g n;
  fun get_adj_inputs g n = filtered_adj_vnames (is_input_vertex g) g n;
  fun get_adj_outputs g n = filtered_adj_vnames (is_output_vertex g) g n;
  
  (* IMPROVE: move these into graph *)
  fun pair_from_of_edge g e = 
      let val (ed,(from,to)) = get_edge g e in (e,ed,from) end;
  fun pair_to_of_edge g e = 
      let val (ed,(from,to)) = get_edge g e in (e,ed,to) end;
  
  (* find all adjacent vertices, except self, divided into: 
     boundary, and others *)
  fun adj_tgt_info' g n0 (d,(ins,outs)) = 
      let 
        fun consider_edge (e,ed,n) (loopes, others) = 
            if V.name_eq (n,n0) then 
              (E.NTab.update (e, ed) loopes, others)
            else (loopes, V.NSet.add n others);
      in 
        (d, (E.NTab.empty, V.NSet.empty)
              |> (E.NSet.fold (consider_edge o (pair_from_of_edge g)) ins)
              |> (E.NSet.fold (consider_edge o (pair_to_of_edge g)) outs))
      end;
  
  fun adj_tgt_info g n =  adj_tgt_info' g n (get_vertex g n);
  
  
  
  (* 
  (* find all adjacent vertices, except self, divided into: 
     boundary, and others *)
  fun adj_info' g n0 (d,(ins,outs)) = 
      let 
        fun consider_edge eh adjinfo = 
            let val n = get_ehn_vname g (H.other eh) 
                val en = H.get_ename eh in
            if V.name_eq (n,n0) then  (* loop *)
              (leaftab, E.NTab.update (en,fst (get_edge g en)) loopes, others)
            else if V.NSet.contains others n then adjinfo
            else if V.NTab.contains leaftab n then 
              (V.NTab.delete n leaftab, loopes,
               V.NSet.add n others)
            (* IMPROVE: avoid edge data lookup when we later throw 
               away things from boundary set... *)
            else if is_boundary g n then 
              (V.NTab.ins (n,(eh,fst (get_edge g en))) leaftab, loopes, others)
            else 
              (leaftab, loopes, V.NSet.add n others)
            end;
      in 
        (d, (V.NTab.empty, E.NTab.empty, V.NSet.empty)
              |> (E.NSet.fold (consider_edge o H.mk_end) ins)
              |> (E.NSet.fold (consider_edge o H.mk_start) outs))
      end;
  
  fun adj_info g n = adj_pat_info' g n (get_vertex g n);
  *)
  
  
  
  (* find all adjacent vertices, except self, divided into: 
     boundary, and others *)
  fun adj_pat_info' g n0 (d,(ins,outs)) = 
      let 
        fun consider_edge eh (adjinfo as (leaftab, loopes, others)) = 
            let val n = get_ehn_vname g (H.other eh) 
                val en = H.get_ename eh in
            if V.name_eq (n,n0) then 
              (leaftab, E.NTab.update (en,fst (get_edge g en)) loopes, others)
            else if V.NSet.contains others n then adjinfo
            else if V.NTab.contains leaftab n then 
              (V.NTab.delete n leaftab, loopes,
               V.NSet.add n others)
            (* IMPROVE: avoid edge data lookup when we later throw 
               away things from boundry set... *)
            else if is_boundary g n then 
              (V.NTab.ins (n,(eh,fst (get_edge g en))) leaftab, loopes, others)
            else 
              (leaftab, loopes, V.NSet.add n others)
            end;
      in 
        (d, (V.NTab.empty, E.NTab.empty, V.NSet.empty)
              |> (E.NSet.fold (consider_edge o H.mk_end) ins)
              |> (E.NSet.fold (consider_edge o H.mk_start) outs))
      end;
  
  fun adj_pat_info g n = adj_pat_info' g n (get_vertex g n);

end; (* OpenGraphFun *)
