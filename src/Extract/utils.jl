function _copy_files_to_dir(files, dir)
  for file in files
    filename = last(splitpath(file))
    cp(joinpath(file), joinpath(dir, filename))
  end
end

function formatcpc(cpc)
  contains("/")(cpc) || return cpc
  before, after = split(strip(cpc), "/")
  length(before) == 8 && return before * "/" * after
  first4, rest = before[1:4], before[5:end]
  spaces = repeat(" ", 4 - length(rest))
  return first4 * spaces * rest * "/" * after
end
