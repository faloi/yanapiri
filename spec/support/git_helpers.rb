module GitHelpers
  def commit_archivo_nuevo!(nombre)
    crear_archivo!(nombre)
    repo.add
    repo.commit "Creado #{nombre}"
    repo.log.first
  end

  def crear_archivo!(nombre)
    repo.chdir {FileUtils.touch nombre}
  end

  def crear_repo!(nombre)
    remote_path = Dir.mktmpdir
    Git.init remote_path, {bare: true, repository: remote_path}
    Git.clone remote_path, nombre, {path: "#{git_base_path}/#{nombre}"}
  end

  def git_base_path
    @git_base_path ||= Dir.mktmpdir
  end

  def commits
    repo.log.to_a.reverse
  end
end
