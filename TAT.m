function TURNAT = TAT(actype,Nodes,tat)
    
    TURNAT =[];
    for k = 1:actype
        TAT_k = tat(k)*ones(Nodes,Nodes); 
        for i=1:Nodes
            for j=1:Nodes
                if j==1
                    TAT_k(i,j)=2*TAT_k(i,j);
                end
                if i==1 || j==1
                    if TAT_k(i,j)<= 1
                        TAT_k(i,j)= 1;
                    end
                end
                if i==j
                    TAT_k(i,j)=0; 
                end
            end
        end
        TURNAT = [TURNAT; TAT_k];
    end
end                