function multifleettrial()
%%  Initialization
    %addpath('/Users/Claudia/Documents/MSc-1/Q2/AE4423/Airline-Planning');
clear all
clearvars
close all
%     warning('off','MATLAB:lang:badlyScopedReturnValue')
%     warning('off','MATLAB:xlswrite:NoCOMServer')
%     savepath
try
%%  Determine input
%   Select input file and sheet
filename    =  'Trial.xlsx';

Nodes       =   6;
ACtype      =   2;


[~,airport,~] = xlsread(filename,1,'A2:A7');          %name ot the airports
distance    =   xlsread(filename,1,'B11:G16');            %OD distance

demand      =   xlsread(filename,1,'B20:G25');            %OD demand

ACchar      =   xlsread(filename,1,'B29:C37'); %Aircraft characteristics;            
cost        =   ACchar(1,:);
LF          =   ACchar(2,:);
nseats      =   ACchar(3,:);
speed       =   ACchar(5,:);
LTO         =   ACchar(6,:);
BT          =   ACchar(7,:);
nfleet      =   ACchar(8,:);
yield       =   0.16;

gi = zeros(1,Nodes);
for i = 1 : Nodes
    if i == 1
       gi(i) = 0;
    else
       gi(i) = 1;
    end
end
gj = zeros(1,Nodes);
for j = 1 : Nodes
    if j == 1
       gj(j) = 0;
    else
       gj(j) = 1;
    end
end

%%  Initiate CPLEX model
%   Create model
        model                   =   'MF_model';
        cplex                   =   Cplex(model);
        cplex.Model.sense       =   'maximize';
%   Decision variables
        DV                      =  Nodes*Nodes + Nodes*Nodes + Nodes*Nodes*ACtype;  %X + W + Z
%     
%         
%%  Objective Function
         %Prepare a matrix of OF coefficients for X and W
         distance = reshape(distance,Nodes*Nodes,1);
         % direct flow 
         X        = distance*yield; 
         % flow from airport transfer in hub
         W        = distance*yield; 
         Z        = zeros(Nodes*Nodes,ACtype);
         for k=1:ACtype
             Z(:,k) = distance*cost(k)*nseats(k);
         end
         % number of flights with aircraft type    
         Z        = reshape(Z,Nodes*Nodes*ACtype,1);     
         obj      =   [X;W;Z];
         lb                     =   zeros(DV,1);
         ub                     =   inf(DV,1);
         ctype                  =   char(ones(1,(DV))*('I'));
         
        l = 1;    % Array with DV names
        for i = 1:Nodes
            for j = 1:Nodes  % of the x_{ij} variables
                NameDV (l,:)  = ['X_' num2str(i) ',' num2str(j) '_' num2str(0)];
                l = l + 1;
            end
        end
        for i = 1:Nodes
            for j = 1:Nodes  % of the w_{ij} variables
                NameDV (l,:)  = ['W_' num2str(i) ',' num2str(j) '_' num2str(0)];
                l = l + 1;
            end
        end
        for k =1:ACtype
            for i = 1:Nodes
                for j = 1:Nodes % of the z_{ij}^k variables
                    NameDV (l,:)  = ['Z_' num2str(i) ',' num2str(j) '_' num2str(k)];
                    l = l + 1;
                end
            end
        end
        cplex.addCols(obj, [], lb, ub, ctype, NameDV);
   
%%  Constraints
%  C1: Demand constraint    
    C1 = zeros(1,DV);
    for i = 1:Nodes
        for j = 1:Nodes
            C1(Xindex(1,j))= 1;
            C1(Windex(i,j))= 1;
        end
    end
    cplex.addRows(0,C1,demand(i,j),sprintf('Demand Constraint%d_%d_%d',i,j));
    
%   C2: Transfer passenger constraint
    C2 = zeros(1,DV);
    for i = 1:Nodes
        for j = 1:Nodes
            C2(Windex(i,j)) = 1;
        end
    end
    cplex.addRows(0,C2,demand(i,j).*gi(i).*gj(j),sprintf('Demand Constraint%d_%d_%d',i,j));
    
%   C3: Capacity verification constraints
    for i = 1:Nodes
        for j = 1:Nodes
            C3 = zeros(1,DV);
            for m = 1:Nodes
                for k = 1:ACtype
                    C3(Zindex(i,j,k)) = -nseats(k)*-LF(k);
                end
                C3(Windex(i,m))=(1-gj(j));
                C3(Windex(m,j))=(1-gi(i));
            end
            C3(Xindex(i,j))=1;
            cplex.addRows(-inf,C3,0,sprintf('CapacityVerification'));
        end
    end
    
%   C4: Flow balance
    for i = 1:Nodes
        for k = 1:ACtype
            C4 = zeros(1,DV);
            for j = 1:Nodes
                C4(Zindex(i,j,k)) =  1;
                C4(Zindex(j,i,k)) = -1;
            end
            cplex.addRows(0,C4,0,sprintf('FlowBalanceNode%d_%d',i,k));
        end
    end
    
%   C5: Aircraft utilization
    for k = 1:ACtype
        C5 = zeros(1,DV);
        for i = 1:Nodes
            for j = 1:Nodes
                C5(Zindex(i,j,k)) = (distance(i,j)/speed(k)+LTO(k));
            end
        end
        cplex.addRows(0,C5,BT(k)*nfleet(k),sprintf('AC utilization'));
    end
    
%%  Execute model
%   Run CPLEX
        cplex.solve();
        cplex.writeModel([model '.lp']);
                
% %%  Postprocessing
% %   Store direct results
%     status                      =   cplex.Solution.status;       
%     if status == 101 || status == 102 || status == 105
%         sol.profit = cplex.Solution.objval;
%         for k = 1:ACtype
%             sol.Freq (:,:,k)= round(reshape(cplex.Solution.x(Zindex(1,1,k):Zindex(Nodes, Nodes, k)), Nodes, Nodes))';
%         end
%         sol.DirFlow(:,:)= round(reshape(cplex.Solution.x(Xindex(1,1):Xindex(Nodes, Nodes)), Nodes, Nodes))';
%         sol.ConFlow(:,:)= round(reshape(cplex.Solution.x(Windex(1,1):Windex(Nodes, Nodes)), Nodes, Nodes))';
%     end
%     
% %   Write output
%     fprintf('\n-----------------------------------------------------------------\n');
%     fprintf ('Objective function value: %10.1f \n', sol.profit);
%     fprintf ('\n')
%     fprintf ('Link From To Direct_Flow Connect_Flow Total Freq_1 Freq_2 Cost \n');
%     NL = 0;
%     for i = 1:Nodes
%         for j = 1:Nodes
%             for k = 1:ACtype
%                 if cost(k)*distance(i,j)*nseats(k)<10000
%                     NL = NL+1;
%                     if sol.DirFlow(i,j)+sol.ConFlow(i,j)-sol.Freq(i,j,k)>0
%                         fprintf('%2d /t %s \t %s \t %5d %5d %6d %4d %5d %6d \n', NL, airport{i}, ...
%                         airport{j}, sol.DirFlow (i,j), sol.ConFlow (i,j), ...
%                         sol.DirFlow (i,j)+sol.ConFlow (i,j), sol.Freq(i,j,k), sol.Freq(i,j,k), ...
%                         yield*distance(i,j)*(sol.DirFlow(i,j)+sol.ConFlow(i,j))-cost(k)*distance(i,j)*nseats(k)*sol.Freq(i,j,k));
%                     end
%                 end
%             end
%         end
%     end
end
    function out = Xindex(m,n)
    out = Nodes*Nodes*ACtype + (m - 1) * Nodes + n;
    end
    function out = Windex(m,n)
    out = Nodes*Nodes*ACtype + (m - 1)*Nodes + n;
    end
    function out = Zindex(m, n, p)
    out = (m - 1) * Nodes + n + Nodes*Nodes*(p-1);
    end
end
   
        
        
        
        
        