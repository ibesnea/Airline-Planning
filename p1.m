%% Initialization
    addpath('/Users/Claudia/Documents/MSc-1/Q2/AE4423/Airline-Planning')
    clearvars
    clc
    close all
%% Input
    [d,airports] = distance('group11.xlsx');
    [C,Yield,k] = opcost('group11.xlsx');
    
    Nodes   = airports(2);          %Number of airports;
    acType  = k;
%% Initiate CPLEX Model
%   Create model
        model                   =   'Problem1_Model';
        cplex                   =   Cplex(model);
        cplex.Model.sense       =   'maximize'; 

%   Decision variable
        DV                      =  Nodes*Nodes*(acType+2);
%% Objective Function 
        obj = reshape([ Yield ; Yield; reshape(C,3,Nodes*Nodes)],DV,1);