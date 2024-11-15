printf "#define STB_IMAGE_IMPLEMENTATION\n#include \"stb_image.h\"" > stb_image_wrapper.c
gcc -o stb_image_wrapper.o -c stb_image_wrapper.c -no-pie

nasm -f elf64 program.s
ld -o program program.o stb_image_wrapper.o -lc -lm -dynamic-linker /lib64/ld-linux-x86-64.so.2
