SET pyexe=C:\Python\python.exe
SET pyscript=C:/cygwin/home/plibauer/python/make_env.py
SET config=C:/cygwin/home/plibauer/python/make_env.config

FOR %%A IN (83 90 91 92 93 94) DO ( %pyexe% %pyscript% --config %config% %%A > %%A"environment") 
