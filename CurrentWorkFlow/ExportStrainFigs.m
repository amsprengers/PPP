function time = ExportStrainFigs(FileName,zdim)
% write all content of SDN strain to figs and move to storepath
tic
dos('rm *.png');
SDNStrain = niftiread([FileName,'_SDNStrain_Eul.nii']);
SDNStrain = SDNStrain/max(SDNStrain(:));

ImsCC     = niftiread([FileName,'_CC_R_L.nii']);
ImsCC      = abs(ImsCC);
CCMask   = zeros(size(ImsCC));
for ii = 1:size(ImsCC,3)
    CCMask(:,:,ii) = imbinarize(ImsCC(:,:,ii));
end
ImsCC = CCMask.*ImsCC;
SDNMask = niftiread([FileName,'_Mask.nii']);
SDNMask(SDNMask==0)=NaN;
%SDNStrain = mat2gray(SDNStrain);

SDNStrain = SDNMask.*SDNStrain;
pad_siz             = (size(ImsCC,2)-size(SDNStrain,2));
pad_sizC1            = (abs(pad_siz)+pad_siz)/2;
pad_sizC2            = (abs(pad_siz)-pad_siz)/2; % --> i.e. define "conjugates so we can pad whichever set is smallest
scrsz               = get(0,'Screensize');
Cmap          = [flip(colormap(gray(128)),1);imresize(buildcmap('rykgb'),[128 3],'nearest')];

ImsCC = -mat2gray(ImsCC);
ImsCC(ImsCC ==0)=NaN;
        for n = 1:zdim
            n1                    = n;
            n2                    = n1+zdim;
            MLOR                  = SDNStrain(:,:,n1); 
            MLOL                  = SDNStrain(:,:,n2);
            CCR                   = ImsCC(:,:,n1);     
            CCL                   = ImsCC(:,:,n2);
            Panel                 = cat(1,padarray(cat(2,MLOR,flip(MLOL,2)),[0 pad_sizC1],NaN,'both'),padarray(cat(2,CCR,flip(CCL,2)),[0 pad_sizC2],NaN,'both'));
            %Panel                 = abs(Panel);
            %Panel(                  Panel==0)=NaN;
            close all
            f_label   = [FileName,'_SDNStrain_slice',getprefix(n,10),num2str(n)];
            f         = dipshow(Panel,'Lin',colormap(Cmap));
            set(f,'Position',[scrsz(1) scrsz(2) size(Panel,2)*scrsz(4)/size(Panel,1) scrsz(4)]);
            diptruesize(f,'off');
            export_fig(gcf,f_label,'-png','-c[NaN,NaN,NaN,NaN]','-opengl','-r300');
            export_fig(gcf,f_label,'-svg','-c[NaN,NaN,NaN,NaN]','-opengl','-r300');
   
        end
        time = toc;
        fprintf(['Wrote Summed- Demeaned- Normalized Strain to .png & .svg format in ',toc',' seconds. \n']);
end
