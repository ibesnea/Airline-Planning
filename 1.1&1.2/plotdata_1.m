clearvars
clear all

fileID      = fopen('1-1t.txt','r');
formatSpec  = '%f \n';
sol.x       = fscanf(fileID,formatSpec);
fclose(fileID);

nodes = 20;


x   = transpose(reshape(sol.x(1:nodes*nodes),nodes,nodes));
w   = transpose(reshape(sol.x(nodes*nodes+1:nodes*nodes*2),nodes,nodes));
z1  = transpose(reshape(sol.x(nodes*nodes*2+1:nodes*nodes*3),nodes,nodes));
z2  = transpose(reshape(sol.x(nodes*nodes*3+1:nodes*nodes*4),nodes,nodes));
z3  = transpose(reshape(sol.x(nodes*nodes*4+1:nodes*nodes*5),nodes,nodes));

filename   = 'data.xlsx';
lat        = xlsread(filename,11,'C6:V6');
long       = xlsread(filename,11,'C7:V7');
max_lat    = round(max(lat));
min_lat    = floor(min(lat));
max_long    = round(max(long));
min_long    = floor(min(long));
[~, nodenames]   = xlsread(filename,11,'C4:V4');
p = plot(graph(x,nodenames,'upper'),'XData', long, 'YData', lat);
xlim([-25 32])
ylim([min_lat  65])
t = title('Optimal Network at the start of operations');
t.FontSize = 15;
p.NodeColor = 'b';
p.LineWidth = 0.5;
p.MarkerSize= 5
p.LineStyle =  '-'
p.EdgeColor = 'b';
highlight(p,1,'MarkerSize',7,'NodeColor','g')
xl = xlabel('Longitude (°)');
xl.FontSize = 12; 
yl = ylabel('Latitude (°)')
yl.FontSize = 12;
nl = p.NodeLabel;
p.NodeLabel = '';
xd = get(p, 'XData');
yd = get(p, 'YData');
text(xd, yd, nl, 'FontSize', 10,'HorizontalAlignment','left', 'VerticalAlignment','Bottom')