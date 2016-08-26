function [model] = libsvmtrain(training_label_vector, training_instance_matrix, libsvm_options)
%LIBSVMTRAIN performs libsvm model building or cross-validation estimation.
%   Usage: [model or cross-validation_prediction_matrix, train time statistics] = libsvmtrain(training_label_vector, training_instance_matrix, 'libsvm_options');
%   libsvm_options:
%   -s svm_type : set type of SVM (default 0)
%   	0 -- C-SVC		(multi-class classification)
%   	1 -- nu-SVC		(multi-class classification)
%   	2 -- one-class SVM
%   	3 -- epsilon-SVR	(regression)
%   	4 -- nu-SVR		(regression)
%   -t kernel_type : set type of kernel function (default 2)
%   	0 -- linear: u'*v
%   	1 -- polynomial: (gamma*u'*v + coef0)^degree
%   	2 -- radial basis function: exp(-gamma*|u-v|^2)
%   	3 -- sigmoid: tanh(gamma*u'*v + coef0)
%   	4 -- precomputed kernel (kernel values in training_instance_matrix)
%   -d degree : set degree in kernel function (default 3)
%   -g gamma : set gamma in kernel function (default 1/num_features)
%   -r coef0 : set coef0 in kernel function (default 0)
%   -c cost : set the parameter C of C-SVC, epsilon-SVR, and nu-SVR (default 1)
%   -n nu : set the parameter nu of nu-SVC, one-class SVM, and nu-SVR (default 0.5)
%   -p epsilon : set the epsilon in loss function of epsilon-SVR (default 0.1)
%   -m cachesize : set cache memory size in MB (default 100)
%   -e epsilon : set tolerance of termination criterion (default 0.001)
%   -h shrinking : whether to use the shrinking heuristics, 0 or 1 (default 1)
%   -b probability_estimates : whether to train a SVC or SVR model for probability estimates, 0 or 1 (default 0)
%   -wi weight : set the parameter C of class i to weight*C, for C-SVC (default 1)
%   -v n : n-fold cross validation mode
%   -q : quiet mode (no outputs)
%   -rnd n : random generator seed (time by default)
%   -max_iter n : stopping train maximum iterations number
%   -timeout sec: stopping train timeout in seconds
