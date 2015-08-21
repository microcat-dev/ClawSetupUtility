url_vm = "https://codeload.github.com/microcat-dev/claw-vm/zip/master"
url_bytecode = "http://microcat.muessigb.net/bytecode/?output=c-header"
url_assembler = "https://codeload.github.com/microcat-dev/ClawAssembler/zip/master"
url_audiostudio = "https://codeload.github.com/microcat-dev/ClawAudioStudio/zip/master"

clawdir = "claw"

zip_vm = "claw-vm.zip"
zip_assembler = "ClawAssembler.zip"
zip_audiostudio = "ClawAudioStudio.zip"

file_vm = "claw-vm-master"
file_assembler = "ClawAssembler-master/ClawAssembler/bin/Release"
file_bytecode = file_vm.."/bytecode.h"
file_audiostudio = "ClawAudioStudio-master/ClawAudioStudio/bin/Release"

cmd_build_vm = "gcc -Wall --std=c11 -o claw-vm.exe claw-vm-master\\vm.c"
cmd_compile = clawdir.."\\ClawBinaryCompiler.exe"
cmd_run = clawdir.."\\claw-vm.exe <file>"

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function checkargs(n, err)
	if #arg<n then
		error(err)
	end
end

function checkoverwrite()
	if arg[2] == arg[3] then
		error("Error: output overwrites source file!")
	end
end

function download(c, url, out)
	local f = assert(io.open(out, "wb"))
	c:setopt(curl.OPT_URL, url)
	c:setopt(curl.OPT_HTTPHEADER, "Connection: Keep-Alive", "Accept-Language: en-us")
	c:setopt(curl.OPT_CONNECTTIMEOUT, 30)
	c:setopt(curl.OPT_FOLLOWLOCATION, true)
	c:setopt(curl.OPT_SSL_VERIFYPEER, false)
	c:setopt(curl.OPT_ENCODING, "utf8")
	c:setopt(curl.OPT_HEADER, false)
	c:setopt(curl.OPT_WRITEFUNCTION, function(param, buf)
		f:write(buf)
		return #buf
	end)
	c:setopt(curl.OPT_NOPROGRESS, true)
	assert(c:perform())
	f:close()
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String, End)
	return End == '' or string.sub(String, -string.len(End)) == End
end

function unzip(zipFilename)
	local zfile = zip.open(zipFilename)
	for file in zfile:files() do
		if file.filename:ends("/") then
			lfs.mkdir(file.filename)
		else
			local currFile = zfile:open(file.filename)
			local currFileContents = currFile:read("*a")
			currFile:close()
			local hBinaryOutput = io.open(file.filename, "wb")

			if hBinaryOutput then
				hBinaryOutput:write(currFileContents)
				hBinaryOutput:close()
			end
		end
	end
	zfile:close()
end

function unzipDir(zipFilename, dir)
	local zfile = zip.open(zipFilename)
	for file in zfile:files() do
		if file.filename:starts(dir) then
			local filename = file.filename:sub(#dir+2)
			if filename ~= "" then
				if filename:ends("/") then
					lfs.mkdir(filename)
				else
					local currFile = zfile:open(file.filename)
					local currFileContents = currFile:read("*a")
					currFile:close()
					local hBinaryOutput = io.open(filename, "wb")

					if hBinaryOutput then
						hBinaryOutput:write(currFileContents)
						hBinaryOutput:close()
					end
				end
			end
		end
	end
	zfile:close()
end

function deleteDir(dir)
	dirs, err = lfs.dir(dir)
	for file in dirs do
		if file ~= "." and file ~= ".." then
			deleteDir(dir.."/"..file)
			os.remove(dir.."/"..file)
			lfs.rmdir(dir.."/"..file)
		end
	end
	a, err = lfs.rmdir(file_vm)
end

function update()
	print("Updating CLAW sdk...")

	print("Loading libraries...")
	http = require("socket.http")
	ltn12 = require("ltn12")
	zip = require("zip")
	curl = require "luacurl"
	require "lfs"
	local c = curl.new()
	
	lfs.mkdir(clawdir)
	lfs.chdir(clawdir)
	
	print("Downloading CLAW VM source...")
	download(c, url_vm, zip_vm)

	print("Extracting CLAW VM source...")
	unzip(zip_vm)

	print("Downloading bytecode header...")
	download(c, url_bytecode, file_bytecode)

	print("Building VM...")
	assert(os.execute(cmd_build_vm))

	print("Downloading CLAW Assembler...")
	download(c, url_assembler, zip_assembler)

	print("Extracting CLAW Assembler...")
	unzipDir(zip_assembler, file_assembler)
	
	print("Downloading CLAW Audio Studio...")
	download(c, url_audiostudio, zip_audiostudio)

	print("Extracting CLAW Audio Studio...")
	unzipDir(zip_audiostudio, file_audiostudio)

	print("Cleaning up...")
	os.remove(zip_vm)
	os.remove(zip_assembler)
	os.remove(zip_audiostudio)
	deleteDir(file_vm)
	c:close()

	lfs.chdir("..")
	print("Done")
end

function run(file)
	assert(os.execute(cmd_run:gsub("<file>", file)))
end

function assemble(file, out)
	assert(os.execute(cmd_compile:gsub("<file>", file):gsub("<out>", out)))
end

checkargs(1, "Error: Missing command.\nUse \"claw.lua h\" for more info.")

if arg[1] == "r" then
	checkargs(2, "Error: Missing command.\nUsage: claw.lua r <file>")
	run(arg[2])
elseif arg[1] == "a" then
	checkargs(3, "Error: Missing command.\nUsage: claw.lua c <file> <out>")
	checkoverwrite()
	assemble(arg[2], arg[3])
elseif arg[1] == "ar" then
	checkargs(3, "Error: Missing command.\nUsage: claw.lua cr <file> <out>")
	checkoverwrite()
	assemble(arg[2], arg[3])
	run(arg[3])
elseif arg[1] == "u" then
	update()
elseif arg[1] == "h" then
	print([[claw.lua - claw sdk utility program.
Usage: claw.lua <option> [file] [file]

options:
r <file>         - Run <file>.
c <file> <out>   - Assemble <file> and save the bytecode in <out>.
cr <file> <out>  - Assemble <file> and save the bytecode in <out>, then run <out>.
u                - Update or install the assembler and virtual machine.
h                - Display this help message.]])
end