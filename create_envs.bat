SET pyscript=C:/cygwin/home/plibauer/python/make_env.py
SET config=C:/cygwin/home/plibauer/python/make_env.config

FOR %%A IN (83 90 91 92 93 94) DO (python.exe %pyscript% --config %config% %%A > %%A"environment") 
