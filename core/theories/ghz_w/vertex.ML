signature GHZW_UNIFIABLE_DATA =    
sig
  datatype node = GHZ | W | TICK | ZERO;
  include UNIFIABLE_DATA
  sharing type data = node;
end;

structure GHZW_VertexData
: GHZW_UNIFIABLE_DATA
= struct
  datatype node = GHZ | W | TICK | ZERO;
  type data = node;
  
  fun data_int ZERO = 0
    | data_int TICK = 1
    | data_int GHZ  = 2
    | data_int W    = 3
  
  fun data_ord (x,y) = int_ord (data_int x, data_int y)
  fun data_eq (n1, n2) = case data_ord (n1, n2) of EQUAL => true | _ => false;
  fun pretty_data ZERO = Pretty.str "ZERO"
    | pretty_data GHZ = Pretty.str "GHZ"
    | pretty_data W = Pretty.str "W"
    | pretty_data TICK = Pretty.str "TICK";
  val print_data = Pretty.writeln o pretty_data;
    
  fun match_data (GHZ, GHZ) m = SOME m
    | match_data (W,W) m = SOME m
    | match_data (TICK,TICK) m = SOME m
    | match_data (ZERO,ZERO) m = SOME m
    | match_data _ m = NONE;
  fun unify_data _ _ = SOME ();
    
  type subst = unit;
  val empty_subst = ();
  fun compose_subst _ = ();
  fun subst_in_data _ d = d;  
  
  fun pretty_subst _ = Pretty.str "";
  val print_subst = Pretty.writeln o pretty_subst;
  
  val default_data = GHZ; 
  
  structure Sharing = struct type data = data; type subst = subst; end; 
end;


(*  *)
structure GHZW_VertexComponentData_Param
: ELEMENT_COMPONENT_DATA_PARAM where type data = GHZW_VertexData.data
= struct 
  type data = GHZW_VertexData.data;
  exception unknown_type_exp of string;

  fun type_of GHZW_VertexData.GHZ = "GHZ"
    | type_of GHZW_VertexData.W = "W"
    | type_of GHZW_VertexData.TICK = "TICK"
    | type_of GHZW_VertexData.ZERO = "ZERO"

  fun cdata_of _ = ComponentData.Unit;

  fun default_data "GHZ" = GHZW_VertexData.GHZ
    | default_data "W" = GHZW_VertexData.W
    | default_data "TICK" = GHZW_VertexData.TICK
    | default_data "ZERO" = GHZW_VertexData.ZERO
    | default_data n = raise unknown_type_exp n;

  fun update _ = I;
end;
