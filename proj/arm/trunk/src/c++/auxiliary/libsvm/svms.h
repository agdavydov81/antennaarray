#ifndef _LIBSVMS_H
#define _LIBSVMS_H

#include <istream>

#ifdef __cplusplus
extern "C" {
#endif

#include "svm.h"

svm_model *svm_load_model_from_stream(std::istream& file);
svm_model *svm_load_model_from_string(const char *model_content);
svm_model *svm_load_model_from_file(const char *model_file_name);
	
#ifdef __cplusplus
}
#endif

#endif /* _LIBSVMS_H */
