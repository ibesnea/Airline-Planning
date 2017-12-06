k = 5                              % k = ACtype
Nodes = 19                         % Nodes = 19

TAT = xlsread('group11.xlsx',1,'B45:F45');
TATij = zeros(Nodes,Nodes,k)
for k=1:k                          %1: ACtype (e.g. 5)
    for i=1:Nodes                  %1: Nodes (e.g. 19)
        for j=1:Nodes              %1: Nodes (e.g. 19)
            if j == i                
                TATij(i,j,k) = 0;
            elseif j == 1                %i = the "hub" node
                TATij(i,j,k) = 2*TAT(k)/60;
            elseif i == 1 
                if TAT(k) < 1
                    TATij(i,j,k) = 1;
                else
                    TATij(i,j,k) = TAT(k)/60;
                end
            else
                TATij(i,j,k) = TAT(k)/60;
            end
        end
    end
end


            
           
                
                