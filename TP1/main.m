clear all; close all; clc

An_img = imread('/home/asuna/Documents/Licenciatura2-3anos/1_semestre/Robotica/TP1/allSignals.png');

%% setup da camara
NumberFrameDisplayPerSecond = 30;% Define o Frame Rate
% Liberta a Camara ao Correr o Codigo
objects = imaqfind; % Encontra Entrada de Video na Memoria
delete(objects)

% Set-up da Entrada de Video
try
    vid = videoinput('winvideo', 1, 'RGB24_1280x720');% Windows
catch
    try
        vid = videoinput('macvideo', 1); % Macs.
    catch
        errordlg('No webcam available');% Em caso de erro
    end
end

% Define os Parametros para o Video
set(vid,'FramesPerTrigger',1);% Aquisicao de um Frame
set(vid,'TriggerRepeat',Inf);% Aquisicao Continua
set(vid,'ReturnedColorSpace','RGB');% Aquisicao de Imagem em RGBa
triggerconfig(vid, 'Manual');
while true
    % Timer que Chama a Funcao Processamento
    TimerData=timer('TimerFcn', {@Processamento,vid},'Period',1/NumberFrameDisplayPerSecond,'ExecutionMode','fixedRate','BusyMode','drop');

    start(vid); %Inicio do Video
    start(TimerData); %Inicio do Timer
end

%     Apaga os Objectos Criados
stop(TimerData);
delete(TimerData);
stop(vid);
delete(vid);
% Apaga as Variaveis do Tipo Persistent
clear functions;
imaqreset;


%% Função Processamento
function Processamento(obj, event,vidd)% Funcao que e chamada de n em n segundo
% Variaveis do Tipo Persistent para Evitar Estar Sempre a Alocar Memoria
persistent im;

trigger(vidd);% Da um Trigger
im = getdata(vidd,1,'uint8');%l? os dados da imagem

% Declaração de variáveis
% n = 0; 
% maskRed = 0;
% maskYellow = 0;
% maskBlue = 0;
im = flip(im ,2); % Espelhar a Imagem, pois a Camara Espelha a Real



%% inicio das cenas
gray = rgb2gray(An_img);
% m_bin = gray > 10;
%
% m_hsv = rgb2hsv(An_img);

%Estas implimentaoes foram tiradas da extensao de imagens, 'Colour
%Thresholder' !!!!

%com tudo a BINARIO ele filtra a deixar so os vermelhos
m_hsv_red = gitRed(An_img);

m_hsv_blue = gitBlu(An_img);

m_hsv_yellow = gitYello(An_img);

%Mostrar a binario e filtrado por cor.
subplot(2,3,1);
imshow(m_hsv_red)
subplot(2,3,2);
imshow(An_img);
imshow(m_hsv_blue)
subplot(2,3,3);
imshow(m_hsv_yellow)

%ver regioes, 'Image Region Analyser'.

%prencher as figuras
bin_fill_red = imfill(m_hsv_red, "holes");
bin_fill_blu = imfill(m_hsv_blue, "holes");
bin_fill_yello = imfill(m_hsv_yellow, "holes");

% %mostrar as imagens preenchidas
% figure,imshow(bin_fill_blu)
% figure,imshow(bin_fill_yello)

%escrever so os circulos, esta funcao foi criada[inicialmente] a partir do
%'image region analizer'
Filter_low_region = filterRegionsCircles(bin_fill_red);
% figure,imshow(Filter_low_region)

CC = bwconncomp(Filter_low_region);
s = regionprops(CC, 'Circularity','Centroid', 'Circularity','MajorAxisLength','MinorAxisLength','Area');

%inicio circulos
circular = cat(1,s.Circularity);

CircleMetric = cat(1, s.Centroid);%Extract centroid coordinates:

%fim circulos

Area = cat(1,s.Area);%extracting the area of the connected components and stores them in the Area variable
Ratio = cat(1,s.MajorAxisLength) - cat(1,s.MinorAxisLength);% calculate the aspect ratio by subtracting the minor axis length from the major axis length

% Initialize TriangleMetric with NaN values for each component
TriangleMetric = NaN(CC.NumObjects, 1);

boxArea = m_minbbarea(Filter_low_region);

%for each boundary, fit to bounding box, and calculate some parameters
for k=1:length(TriangleMetric),
    TriangleMetric(k) = Area(k)/boxArea(k);  %filled area vs box area
end

isCircle = circular > 0.96;

m_idxCirc = cat(1,CC.PixelIdxList{isCircle});%concatenar os pixeis dos circulos, e guardar em m_idxCirc

m_circles = zeros(size(gray, 1), size(gray, 2));%passa td a 0
m_circles(m_idxCirc) = 1;%passar m_idxCirc a 1.
figure,imshow(m_circles)

%inicio triangulos
isTriangle = ~(circular > 0.96) & (TriangleMetric < 0.65);%tirar os circulos, e filtrar deixar os triangulos, quanto mais perto
%de 1 a figura e mais proxima de ser um circulo, senao sera outra figura
%como o triangulo ali apresentado.
m_idxTriang = cat(1,CC.PixelIdxList{isTriangle});
m_triangles = zeros(size(gray, 1), size(gray, 2));
m_triangles(m_idxTriang) = 1;
figure,imshow(m_triangles)
%fim triangulos

%Mostrar o quadrado todo que tem trapezios?
%Juntar os trapezios ao quadrado de volta mas em binario, com fill(pq e a figura toda ocupada)
%fazer um um open a imagem.. e mostrar.

%ver o que e nao triangulo e circulo e passar para a outra imagem, no caso
%os trapezios com o pseudo quadrado.

% Calculate isCircle and isTriangle separately
isCircle = circular > 0.96;
isTriangle = TriangleMetric < 0.65;

isTrapezoid = ~isCircle & ~isTriangle;
m_idxTrapezoid = cat(1,CC.PixelIdxList{isTrapezoid});
m_trapezoids = zeros(size(gray, 1), size(gray, 2));
m_trapezoids(m_idxTrapezoid) = 1;
figure,imshow(m_trapezoids)

%criar variavel para img final, meter tudo a 0 e juntar os 'bits' todos das duas
%imagens ficando uma so.

%..filtrar os losangos fora, meter a zero e separar ou assim xd
m_juncao = bin_fill_yello + m_trapezoids;
figure,imshow(m_juncao)
se = strel('square', 15);
m_close = imclose(m_juncao,se); %fazer fecho da imagem
figure,imshow(m_close)


%fazer ciclo for() para os triangulos e para os circulos, partindo principio para cada cor
%bwconcomp para os circulos vermelhos e fzr um for(), mesma coisa para os
%triangulos e os ...azuis, e ..amarelos.

%depois combinar tudo para grayscale!!!! nos vermelhos e azuis(que tenho so preto e vermelho)
%e azul e branco

%possivel Problema: converter img binaria a gray e a cores dps.

%no for() mostrar a gray e a cores individualmente

%grayscale era o azual e amarelo era a cor.

%help for(), ver como funfa,

%contas gray: img_bin *

%UPDATE!!!!
%passar imgs p/gray e bin, para cor, fzr bwconcomp do num e figuras e fazer
%for() para o num de objectos e passar para grayscale ou cor.
%

% %ver o bwconncomp para circulos
% CC_Circles = bwconncomp(m_circles);
% s_circles = regionprops(CC, 'Centroid', 'Area', 'MajorAxisLength', 'MinorAxisLength', 'Eccentricity', 'PixelIdxList');


CC_Red = bwconncomp(bin_fill_red);
s_red = regionprops(CC_Red, 'Centroid', 'Area');


%1º tentativa, tentar so com a mascara a vermelho+gray+hsv xp, depois ver com bwconncomp
%duvidas, perceber como fazer retorno d


multi = uint8(m_triangles); % Converter para 8bits
submask = An_img.*multi; % Multiplicar a Imagem Binaria com a Original
figure,imshow(submask)



if CC_Red.NumObjects >= 1       %se num objectos for 1 ou mais

    for i = 1:CC_Red.NumObjects %percorrer pelos mesmos

        if numel(CC_Red.PixelIdxList{i}) > 1 
            %code to handle the triangles
            %Invert the mask

            



            % inverted_mask = ~bin_fill_red;
            % for j = 1:CC_Red:NumObjects
            % 
            
            end
        elseif CC_Red.NumObjects == 1

        end

    end

end




%
% %Loop em cada forma:
% for i in
%     %Extrair informacoes sobre as formas
%     centroid = s(i).Centroid;
%     area = s(i).Area;
%     majorAxisLength = s(i).MajorAxisLength;
%     minorAxisLength = s(i).MinorAxisLength;
%     eccentricity = s(i).Eccentricity;
%     pixelIdxList = s(i).PixelIdxList;
%
%     %Aplicar logica para filtrar a forma(de volta a RGB ou cinza)
%     if isCircle(centroid, area, eccentricity)
%     %circle doshit
%     intensity_foreground = 255;
%     intensity_background = 0;
%     m_circles = intensity_background + intensity_background * m_circles;
%     figure,imshow(m_circles)
%
%     elseif isTriangle(majorAxisLength, minorAxisLength)
%     %triangle doshit
%     intensity_foreground = 255;
%     intensity_background = 0;
%     m_triangles= intensity_background + intensity_background * m_triangles;
%     figure,imshow(m_triangles)
%     end
% end
%
%
%
%
