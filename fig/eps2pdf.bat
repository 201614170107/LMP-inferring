for /r %%a in (*.eps) do (
	epstopdf %%a
	del %%a
)
echo success
pause