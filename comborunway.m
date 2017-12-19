function run = comborunway(Nodes,actype,runway,nrunway)
    b = zeros(Nodes,Nodes);
    for i = 1:Nodes
        for j=1:Nodes
            b(i,j) = min(nrunway(i),nrunway(j));
        end
    end
    run = zeros(Nodes,Nodes,actype);
    for k=1:actype
       for i=1:Nodes
           for j=1:Nodes
                if b(i,j)>=runway(k)
                    run(i,j,k) = 1000;
                if j == i
                    run(i,j,k) = 0;
                end
                end
           end
       end
     end
end