function a = combo(d,Nodes,actype,max_range)
    a = [];
    D = zeros(Nodes);
    for k=1:actype
        A = d < max_range(k);
        D(A) = 1000;
        a = [a; D];
    end
end