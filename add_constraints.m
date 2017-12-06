% C6: number aircraft
for i = 1:Nodes
    for j = 1:Nodes
        C6 = zeros(1:DV);
        for k = 1: ACtype
            C6(Nindex(i,j,k)) = 1;              %is n also a variable? Nindex --> nr aircraft
        end
        cplex.addRows(AC,C6,AC,sprintf('FlowBalanceNode%d_%d',k));
    end
end

% C7: range constraint
a = zeros(Nodes,Nodes,ACtype);                  %to define parameter "a"
for i = 1:Nodes
    for j = 1:Nodes
        for k = 1:ACtype
            if distance(i,j) <= R(k)
               a(i,j,k) = 1000;                %or other large number(?)
            end
        end
    end
end

for i = 1:Nodes                                %not sure i,j,k or i,k,j
    for j = 1:Nodes
        C7 = zeros(1:DV);
        for k = 1:ACtype
            C7(Zindex(i,j,k)) = 1;
        end
        cplex.addRows(a(i,j),C7,a(i,j),sprintf('FlowBalanceNode%d_%d',k));
    end
end

