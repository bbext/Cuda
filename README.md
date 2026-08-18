# Cuda — CUDA bindings for BlackBox Component Builder (amd64 Linux)

Биндинги CUDA Toolkit для 64-битного BlackBox (bbcp), по образцу LinDl/LinLibc:
атрибут библиотеки в заголовке модуля + `[ccall]`-объявления. Свой C-код не нужен.

- `CudaRt`  — CUDA Runtime API (`libcudart.so.12`, cuda_runtime.h)
- `CudaBlas` — cuBLAS (`libcublas.so.12`, cublas_v2.h; символы с суффиксом `_v2`)
- `CudaFft` — cuFFT (`libcufft.so.11`, cufft.h)
- `CudaUtil` — CP-обёртки (ErrorText, DeviceName)
- `CudaTest`, `CudaTestBlas`, `CudaTestFft` — smoke-тесты

## Требования

- 64-битный BlackBox world (bbcp + bbcp64use, см. QUICKSTART64.md в bbcp)
- NVIDIA driver + CUDA Toolkit 12 (libcudart/libcublas/libcufft в ldconfig)

## Сборка и тест

```bash
./build.sh                 # скелет в мире + sync .odc.txt -> .odc + компиляция
echo 'CudaTest.Go'     | ~/sources/bbcp/run-bb64 --console
echo 'CudaTestBlas.Go' | ~/sources/bbcp/run-bb64 --console
echo 'CudaTestFft.Go'  | ~/sources/bbcp/run-bb64 --console
```

Мир и bbcp переопределяются переменными `BBCP64USE` и `BBCP`.

## Правила написания биндингов (грабли)

- В модуле с атрибутом `["lib.so"]` — ТОЛЬКО `[ccall]`-объявления без тел;
  обёртки — в соседнем модуле без атрибута (CudaUtil).
- Адрес данных динамического массива: `SYSTEM.ADR(a[0])`
  (`SYSTEM.VAL(LONGINT, a)` указывает на хедер, данные на +28 байт).
- Буфер под C-структуру: локальный `VAR buf: ARRAY N OF SHORTCHAR` +
  параметр `VAR x: ARRAY [untagged] OF SHORTCHAR` в биндинге.
- Нуль-литерал для SHORTCHAR — `0X` (`0S` не существует).
- `float` — SHORTREAL, enum/int — INTEGER, size_t/указатели — LONGINT.
- cuBLAS v2: в .so все символы с суффиксом `_v2` (cublasCreate_v2 и т.д.);
  матрицы column-major. cuFFT: cufftHandle = int (не указатель).

Установка как пакета: через Paket с blackbox.oberon.org (публикация — как у
bbext/Http, github hook публикует репо на сайт).
