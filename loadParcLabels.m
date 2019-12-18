function [networkIDs, allnets] = loadParcLabels

t = readtable('Schaefer2018_1000Parcels_17Networks_order.txt');
networks = {};
networkIDs = [];

for i = 1:height(t)
    label = t(i,:).Var2{1};
    parts = strsplit(label, '_');

    thisnet = parts{3};
    networks{i} = thisnet;
end
for i = height(t)+1:1038
    thisnet = 'SubCort';
    networks{i} = thisnet;
end

allnets = unique(networks);
for i = 1:length(networks)
    networkIDs(i) = find(strcmp(networks{i}, allnets));
end
