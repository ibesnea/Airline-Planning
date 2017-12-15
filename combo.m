function a = combo(d,Nodes,actype,max_range)
    a = zeros(Nodes,Nodes,actype);
    for k=1:actype
       for i=1:Nodes
           for j=1:Nodes
                if d(i,j)<max_range(k);
                    a(i,j,k) = 1000;
                if j ==i
                    a(i,j,k) = 0;
                end
           end
       end
   end
end