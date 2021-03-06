functor DefaultGenerators(
  structure Graph : BANG_GRAPH
) =
struct
  structure Graph = Graph
  
  val id = let
    val gr = Graph.empty
    val (a,gr) = gr |> Graph.add_vertex (Graph.OVData.EVert)
    val (b,gr) = gr |> Graph.add_vertex (Graph.OVData.EVert)
  in (gr |> Graph.doadd_edge (Graph.Directed, Graph.EData.default_data) a b, 1, 1) 
  end
  
  fun gen data (ins, outs) = let
    fun addk 0 gr = (gr, V.NSet.empty)
      | addk k gr = let
          val (v,gr) = gr |> Graph.add_vertex Graph.OVData.EVert
          val (gr,vs) = addk (k-1) gr
    in (gr, V.NSet.add v vs)
    end
    val (iv, gr) = Graph.empty |> Graph.add_vertex (Graph.OVData.IVert data)
    val (gr,invs) = addk ins gr
    val (gr,outvs) = addk outs gr
    val gr = V.NSet.fold (fn v => Graph.doadd_edge (Graph.Directed, Graph.EData.default_data) v iv) invs gr
    val gr = V.NSet.fold (fn v => Graph.doadd_edge (Graph.Directed, Graph.EData.default_data) iv v) outvs gr
  in (gr, ins, outs)
  end
  
  fun gen_list max_arity data_list = let
    fun alist 0 0 = []
      | alist k 0 = (0,k)::alist (k-1) (k-1)
      | alist k i = (i,k-i)::alist k (i-1)
  in id::(fold_product (cons oo gen) data_list (alist max_arity max_arity) [])
  end
end


(*
val gens = [
  gen GHZW_VertexData.GHZ 3 0,
  gen GHZW_VertexData.W 3 0,
  gen GHZW_VertexData.GHZ 2 1,
  gen GHZW_VertexData.W 2 1,
  gen GHZW_VertexData.GHZ 1 2,
  gen GHZW_VertexData.W 1 2,
  gen GHZW_VertexData.GHZ 0 3,
  gen GHZW_VertexData.W 0 3,
  gen GHZW_VertexData.GHZ 2 0,
  gen GHZW_VertexData.W 2 0,
  gen GHZW_VertexData.GHZ 1 1,
  gen GHZW_VertexData.W 1 1,
  gen GHZW_VertexData.W 0 2,
  gen GHZW_VertexData.GHZ 0 2,
  gen GHZW_VertexData.GHZ 1 0,
  gen GHZW_VertexData.W 1 0,
  gen GHZW_VertexData.GHZ 0 1,
  gen GHZW_VertexData.W 0 1
];*)