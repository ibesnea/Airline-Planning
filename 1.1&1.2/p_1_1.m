%%  Initialization
    clc
	clearvars
    close all
    warning('off','MATLAB:lang:badlyScopedReturnValue')
    warning('off','MATLAB:xlswrite:NoCOMServer')
    %%  Determine input
%   Select input file and sheet
    filename = 'data.xlsx';
    [nodes,type,yield,cost,lease,time,seats,combo,fleet] = data_1(filename);
    BT = 70;
    LF = 0.75;
    demand = xlsread(filename,11,'C15:V34');
    hub    = 1;
    g_i   = ones(1,nodes);
    g_j   = ones(1,nodes);
    g_i(hub) = 0;
    g_j(hub) = 0; 
    %%  Initiate CPLEX model
%   Create model
        model                   =   'Problem_1_1';
        cplex                   =   Cplex(model);
        cplex.Model.sense       =   'maximize';

%   Decision variables
        DV                      = nodes*nodes+nodes*nodes+ ...
                                  nodes*nodes*type+type;
    
    %%  Objective Function
        X  = reshape(yield',nodes*nodes,1);     
        W  = reshape(yield',nodes*nodes,1); 
        Z  = zeros(nodes*nodes*type,1);
        for k =1:type
            c  = cost(:,:,k);
            Z((k-1)*nodes*nodes+1:nodes*nodes*k) = reshape(c',nodes*nodes,1);
        end
        N  = lease';
        
        obj = [X;W;-Z;-N];
        
        lb                      =   zeros(DV, 1);                                 % Lower bounds
        ub                      =   inf(DV, 1);                                   % Upper bounds
        ctype                   =   char(ones(1, (DV)) * ('I'));                  % Variable types 'C'=continuous; 'I'=integer; 'B'=binary
       
        l = 1;                                      % Array with DV names  (OPTIONAL, BUT HELPS READING THE .lp FILE)
        for i = 1:nodes
            for j = 1:nodes                          % of the x_{ij} variables
                NameDV (l,:)  = ['X_' num2str(i,'%02d') ',' num2str(j,'%02d') '_' num2str(0,'%02d')];
                l = l + 1;
            end
        end
        for i = 1:nodes
            for j = 1:nodes                          % of the w_{ij} variables
                NameDV (l,:)  = ['W_' num2str(i,'%02d') ',' num2str(j,'%02d') '_' num2str(0,'%02d')];
                l = l + 1;
            end
        end        
        for k =1:type
            for i = 1:nodes
                for j = 1:nodes                     % of the z_{ij}^k variables
                    NameDV (l,:)  = ['Z_' num2str(i,'%02d') ',' num2str(j,'%02d') '_' num2str(k,'%02d')];
                    l = l + 1;
                end
            end
        end
        for k = 1:type                         % of the n^k variables
            NameDV (l,:)  = ['N_' num2str(0,'%02d') ',' num2str(0,'%02d') '_' num2str(k,'%02d')];
            l = l + 1;
        end
        cplex.addCols(obj, [], lb, ub, ctype, NameDV);
       
     %%  Constraints
    %   Flow at each airport leave the airport,either through hub or not
        for i = 1:nodes
            for j = 1:nodes
                C1      =   zeros(1, DV);       %Setting coefficient matrix with zeros
                C1(Xindex(i,j,nodes)) = 1;
                C1(Windex(i,j,nodes)) = 1;
                cplex.addRows(0, C1, demand(i,j),sprintf('FlowLink%d_%d',i,j));
            end
        end
    %   Transfer passengers are only if the hub is not the origin
        for i = 1:nodes
            for j = 1:nodes
                C2      =   zeros(1, DV);       %Setting coefficient matrix with zeros
                C2(Windex(i,j,nodes)) = 1;
                cplex.addRows(0, C2, demand(i,j)*g_i(i)*g_j(j),sprintf('TransferPax%d_%d',i,j));
            end
        end
    %   Capacity verification in each flight leg
        for i = 1:nodes
            for j = 1:nodes
                C3      =   zeros(1, DV);       %Setting coefficient matrix with zeros
                C3(Xindex(i,j,nodes)) = 1;
                for m =1:nodes
                    C3(Windex(i,m,nodes)) = 1-g_j(j);
                    C3(Windex(m,j,nodes)) = 1-g_i(i);
                end
                for k =1:type
                    C3(Zindex(i,j,k,nodes)) = -seats(k)*LF;
                end
                cplex.addRows(-Inf, C3, 0,sprintf('Capacity%d_%d',i,j));
            end
        end
     %   Balance between incoming and outgoing flights at each node        
        for i = 1:nodes
            for k = 1:type
                C4      =   zeros(1, DV);    %Setting coefficient matrix with zeros
                for j = 1:nodes
                    C4(Zindex(i,j,k,nodes))   =    1;              %Link getting IN the node
                    C4(Zindex(j,i,k,nodes))   =   -1;              %Link getting OUT the node
                end
                cplex.addRows(0, C4, 0, sprintf('FlowBalanceNode%d_%d',i,k));
            end
        end
    %  Use of aircraft limited to the number of aircraft and the block hours
    %  associated to it. 
        for k = 1:type
            C5 = zeros(1,DV);
            for i=1:nodes
                for j=1:nodes
                    C5(Zindex(i,j,k,nodes)) = time(i,j,k);
                end
            end
            C5(Nindex(k,type,nodes)) = -BT;
            cplex.addRows(-Inf, C5, 0,sprintf('Usage%d',k));
        end
    %  Maintain the current aircraft fleet.  
        for k = 1:type
            C6 = zeros(1,DV);
            C6(Nindex(k,type,nodes)) = 1;
            cplex.addRows(fleet(k), C6, fleet(k),sprintf('Fleet%d',k));
        end
    %  Flight only between airports where the aircraft range is larger than
    %  the distance
        for i = 1:nodes
            for j = 1:nodes
                for k =1:type
                    C7      =   zeros(1, DV);       %Setting coefficient matrix with zeros
                    C7(Zindex(i,j,k,nodes)) = 1;
                    cplex.addRows(0, C7,combo(i,j,k) ,sprintf('Range%d_%d_%d',i,j,k));
                end
            end
        end    
                    
     %%  Execute model
        cplex.Param.mip.limits.nodes.Cur    = 1e+8;         %max number of nodes to be visited (kind of max iterations)
        cplex.Param.timelimit.Cur           = 10;         %max time in seconds
        
  %Run CPLEX
        cplex.solve();
        cplex.writeModel([model '.lp']);     
      %%  Postprocessing
%   Store direct results
    status          =   cplex.Solution.status;
    sol.profit      =   cplex.Solution.objval;
    sol.x           =   cplex.Solution.x;
    
    x   = transpose(reshape(sol.x(1:nodes*nodes),nodes,nodes));
    w   = transpose(reshape(sol.x(nodes*nodes+1:nodes*nodes*2),nodes,nodes));
    z1  = transpose(reshape(sol.x(nodes*nodes*2+1:nodes*nodes*3),nodes,nodes));
    z2  = transpose(reshape(sol.x(nodes*nodes*3+1:nodes*nodes*4),nodes,nodes));
    z3  = transpose(reshape(sol.x(nodes*nodes*4+1:nodes*nodes*5),nodes,nodes));
    fileID = fopen('1-1_1.txt','w');
    fprintf(fileID,'Objective function value: %f\n',sol.profit);
    fprintf(fileID,'\n\n');
    fprintf(fileID,'%f\n',sol.x);  
    fclose(fileID);
%   Write output
    fprintf('\n-----------------------------------------------------------------\n');
    fprintf ('Objective function value:          %10.1f  \n', sol.profit);
%%  
function out = Xindex(m,n,nodes)
    out = (m - 1) * nodes + n;
end
function out = Windex(m,n,nodes)
    out = nodes*nodes+(m - 1) * nodes + n;
end
function out = Zindex(m,n,p,nodes)
    out = nodes*nodes*2+ (m - 1) * nodes + n + (p-1)*nodes*nodes;
end
function out = Nindex(p,type,nodes)
    out = nodes*nodes*(2+type)+p;
end   