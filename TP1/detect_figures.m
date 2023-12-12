function [whichShape, isCircle, isTriangle, isSquare, isRectangle, BW2] = detect_figures(im)
hFigure = figure(1);% Abre uma figura em tempo real
imshow(im); % apresenta a imagem inicial

BW2 = [];  % Initialize BW2

try
stats =  regionprops(BW2,'PixelIdxList','Area','Centroid','MajorAxisLength','Circularity','MinorAxisLength'); %Retirar todas as Informcoes do Sinal
Area = cat(1,stats.Area); % Area do Sinal
Centroid = cat(1, stats.Centroid); % Centro do Sinal
Ratio = cat(1,stats.MajorAxisLength) / cat(1,stats.MinorAxisLength); %Ratio
MajorAxis = cat(1,stats.MajorAxisLength); % Lado Maior do Sinal
CircleMetric = cat(1,stats.Circularity);  % Circularidade
SquareMetric = Ratio; % Metrica do Quadrado
TriangleMetric = NaN(length(CircleMetric),1);% Metrica do Triangulo

boxArea = m_minbbarea(BW2);

%Para cada Limite, Colocar a Bounding Box e Calcular alguns Parametros
for k=1:length(TriangleMetric),
    TriangleMetric(k) = Area(k)/boxArea(k);  %Area Preenchida VS Area da Box
end
% Definir alguns Limites para Cada Metrica
% Circulo-Triangulo-Quadrado-Retangulo-Pentagono para Evitar a mesma Forma em Varios Objetos
isCircle =   (CircleMetric > 0.85);
isTriangle = ~isCircle & (TriangleMetric < 0.65);
isSquare =   ~isCircle & ~isTriangle & (SquareMetric < 1) & (TriangleMetric > 0.9);
isRectangle = ~isCircle & ~isTriangle & ~isSquare & (TriangleMetric > 0.9);

% Atribuir a Forma a cada Objeto
whichShape = cell(length(TriangleMetric),1);
whichShape(isCircle) = {'Circulo'};
whichShape(isTriangle) = {'Triangulo'};
whichShape(isSquare) = {'Quadrado'};
whichShape(isRectangle)= {'Retangulo'};

catch
        % Handle any errors here, if needed
end
%fim filtro

