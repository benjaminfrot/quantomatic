signature RULE_MATCH_SEARCH_SHARING
= sig
  structure Match : MATCH_SHARING
  structure Rule : RULE_SHARING
  sharing Match.G = Rule.Graph
end;

signature RULE_MATCH_SEARCH
= sig
  structure Match : MATCH 
  structure Rule : RULE
  
  structure Sharing : RULE_MATCH_SEARCH_SHARING 
  sharing Sharing.Match = Match.Sharing
  sharing Sharing.Rule = Rule.Sharing
  
  val match : (V.NSet.T * E.NSet.T * 
               B.NSet.T)
              -> Rule.T -> Match.G.T
              -> Match.T Seq.seq
end;