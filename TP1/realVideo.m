
function realVideo
NumberFrameDisplayPerSecond=20;% Define o frame rate
 
hFigure=figure(1);% Abre uma figura
 
% Set-up da entrada de video

try
        vid = videoinput('winvideo', 1, 'RGB24_1280x720'); % para windows
catch
   try
       vid = videoinput('macvideo', 1); % para macs.
   catch
      errordlg('No webcam available');
   end
end
 
% define os parametros para o video
set(vid,'FramesPerTrigger',1);% adquire apenas um frame
set(vid,'TriggerRepeat',Inf);% adquire em continuo
set(vid,'ReturnedColorSpace','RGB');%adquire imagem do tipo RGB
triggerconfig(vid, 'Manual');
 
% cria um timer que chama a função Processamento
TimerData=timer('TimerFcn', {@Processamento,vid},'Period',1/NumberFrameDisplayPerSecond,'ExecutionMode','fixedRate','BusyMode','drop');
 
start(vid); % inicia o video 
start(TimerData); % inicia o timer 
 
%  activa a função enquanto a janela da figura estiver aberta
 uiwait(hFigure);

% Apaga os objectos criados
stop(TimerData);
delete(TimerData);
stop(vid);
delete(vid);
% apaga as variaveis do tipo persistent
clear functions;
imaqreset;


%esta função é chamada de x em x segundos, valor estabelecido quando foi
%configurado o timer
function Processamento(obj, event,vidd)
%cria variaveis do tipo persistent para evitar estar sempre a alocar
%memoria
persistent IM;
persistent HSV;
persistent H;
persistent S;
persistent V;
persistent out1;
persistent out2;
persistent out3;
persistent out;
 
trigger(vidd);%dá um trigger
IM=getdata(vidd,1,'uint8');%lê os dados da imagem
 
%processamento
HSV = rgb2hsv(IM);
H= HSV (:,:,1);
S= HSV (:,:,2);
V= HSV (:,:,3); 
out1=roicolor(H,200/360,247/360);    
out2=roicolor(S,0/100,100/100);
out3=roicolor(V,0/100,100/100);

out=out3.*out2.*out1;

%mostras as imagens
subplot(1,2,1);imshow(IM);
subplot(1,2,2);imshow(out);


