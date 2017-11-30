%% Initialization
    addpath('/Users/Claudia/Documents/MSc-1/Q2/AE4423/Airline-Planning')
    clearvars
    clc
    close all
%% Input
    [d,airports] = distance('group11.xlsx');
    fleet = xlsread('group11.xlsx','B12:F12');
    
    Nodes   = airports(2);          %Number of airports;
    k = length(find(fleet));        %Types of aircraft; 
    
    Yield = 5.9*(reshape(d,Nodes*Nodes,1)).^(-0.76)+0.043;
    
    %Remove infinite values of Yield and set them to zero for cases where 
    %i=j; 
    indx_y = find(isinf(Yield));
    Yield(indx_y) = 0;
%% Initiate CPLEX Model
%   Create model
        model                   =   'Problem1_Model';
        cplex                   =   Cplex(model);
        cplex.Model.sense       =   'maximize'; 

%   Decision variables
        DV                      = Nodes * Nodes;
  
    