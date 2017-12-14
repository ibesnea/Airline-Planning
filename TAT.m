function totaltime = TAT(actype,Nodes,tat,speed,d)
   TURNAT = zeros(Nodes,Nodes,actype);
   for k=1:actype
        TURNAT(:,:,k) = tat(k);
   end
   for i= 1:Nodes
       for j=1:Nodes
           
           if i == 3
               TURNAT(i,j,:) = 1;
           end
           if j == 3 
               TURNAT(i,j,:) = TURNAT(i,j,:)*2;
           end
           if i == j
              TURNAT(i,j,:) =0;
           end
       end
   end
   
   triptime = zeros(Nodes,Nodes,actype); 
   for k=1:actype
       for i=1:Nodes
           for j=1:Nodes
                triptime(i,j,k) = d(i,j)/speed(k);
           end
       end
   end
   totaltime = triptime + TURNAT;
end                