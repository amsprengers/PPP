function StrainField = CallStrainKroon3D(FileName,zdim)
% load Displacement matrix [Filename] in nifti format 
% Compute Eulerian Strain based on Kroon's algorithm, more to come 
% TotDisp should be formatted a [Xdim,Ydim,2*zdim,2]
% Last dimension contains x & y displacement
% Third dimension contains right side and left side stacked
%ImSides             = {'R','L'};
TotDisp            = niftiread([FileName,'_Displacement.nii']);
siz                = size(TotDisp);
StrainField        = zeros(siz(1),siz(2),zdim*2, 
 %for ImSide = 1:numel(ImSides)
        for n = 1:zdim
            n1                              = n+(ImSide-1)*zdim;
            n2                              = n1+zdim;
            Dx                             = TotDisp(:,:,n1,1);
            Dy                             = TotDisp(:,:,n1,2);
            % imbin                           = logical(imbinarize(im1)+imbinarize(im2));
            StrainField                    = strain(Dx,Dy);
            
        end
 end
%end