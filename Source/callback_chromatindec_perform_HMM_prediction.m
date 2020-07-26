%%
% ChromatinDec.
% Copyright (C) 2020 A. Bhattacharyya, D. Moreno-Andres, J. Stegmaier
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the Liceense at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% Please refer to the documentation for more information about the software
% as well as for installation instructions.
%
% If you use this application for your work, please cite the repository and one
% of the following publications:
%
% TBA
%
%%

function hmmPrediction = callback_chromatindec_perform_HMM_prediction(predictedSequence)

    %% shift all classes by 1 to be consistent with the HMM formulation (labels 1-4 instead of 0-3)
    predictedSequence = predictedSequence + 1;

    %% the HMM has 5 states: start, I, PM, ATI, Invalid
    T = [0.0, 0.5, 0.0, 0.0, 0.5;
         0.0, 0.5, 0.5, 0.0, 0.0;
         0.0, 0.0, 0.5, 0.5, 0.0;
         0.0, 0.0, 0.0, 1.0, 0.0;
         0.0, 0.0, 0.0, 0.0, 1.0];

    
    %% the HMM has 4 symbols: 0, 1, 2, 3 (reflecting invalid, I, PM, ATI, respectively)
    E = [0.49, 0.49, 0.01, 0.01;
         0.01, 0.97, 0.01, 0.01;
         0.01, 0.01, 0.97, 0.01;
         0.01, 0.01, 0.01, 0.97;
         0.97, 0.01, 0.01, 0.01];
     
     %% perform the hmm prediction using the viterbi algorithm
     tempPrediction = hmmviterbi(predictedSequence, T, E);
     
     %% shift the classes back again to a 0-based format
     hmmPrediction = zeros(size(tempPrediction));
     hmmPrediction(tempPrediction == 5) = 0;
     hmmPrediction(tempPrediction == 2) = 1;
     hmmPrediction(tempPrediction == 3) = 2;
     hmmPrediction(tempPrediction == 4) = 3;
end