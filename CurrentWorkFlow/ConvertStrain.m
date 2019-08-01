function [SDNStrain,TrStrain] = ConvertStrain(FileName)
% convert strain tensor by summing over tensor indices, Demeaning and Normalizing
% Right now only works on M2D strain i.e. Multi2D. 
% More complex conversions of Strain to come

%BsDemean            = @(a) a - mean(a);
%BsSum               = @(a) squeeze(sum(sum(a,5),4));
%BsNorm              = @(a) a/max(abs(a(:)));
%BsTotal             = @(a) BsNorm(BsDemean(BsSum(a)));
 
StrainField = niftiread([FileName,'_Strain_Eul']);
SDNStrain = squeeze(sum(sum(StrainField,4),5));
%SDNStrain = BsTotal(StrainField);
TrStrain = StrainField(:,:,:,1,1)+StrainField(:,:,:,2,2);
niftiwrite(SDNStrain,[FileName,'_SDNStrain_Eul.nii']);
niftiwrite(TrStrain,[FileName,'_TrStrain_Eul.nii']);