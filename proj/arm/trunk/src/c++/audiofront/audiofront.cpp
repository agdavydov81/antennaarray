#include <iostream>
#include <portaudio.h>

int main(void) {
	int ret=0;
	bool do_terminate=false;
	PaError pa_err=paNoError;

	try {
		std::cout << "AudioFront 0.0.1" << std::endl;
		std::cout << Pa_GetVersionText() << std::endl;

		if((pa_err=Pa_Initialize())!=paNoError)
			throw std::runtime_error("Pa_Initialize error.");
		do_terminate = true;

		std::cout << "Supported APIs (* - default):" << std::endl;
		for(PaHostApiIndex api_i=0, api_e=Pa_GetHostApiCount(), api_def=Pa_GetDefaultHostApi(); api_i!=api_e; ++api_i) {
			PaHostApiInfo const * cur_api = Pa_GetHostApiInfo(api_i);
			std::cout << (api_i==api_def?"  * ":"    ") << cur_api->name << std::endl;
		}

		std::cout << "Supported devices (o - default output, i - default input):" << std::endl;
		for(PaHostApiIndex dev_i=0, dev_e=Pa_GetDeviceCount(), dev_in=Pa_GetDefaultInputDevice(), dev_out=Pa_GetDefaultOutputDevice(); dev_i!=dev_e; ++dev_i) {

		}

	}
	catch(const std::exception & err) {
		std::cerr << "Exception (std::exception): " << err.what() << std::endl;
		std::cerr << "PortAudio last error: " << Pa_GetErrorText(pa_err) << std::endl;
		ret = -1;
	}

	if(do_terminate)
		Pa_Terminate();

	return ret;
}
