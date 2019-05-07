class Bot
  attr_reader :organization
  
  def initialize(organization, gh_token)
    @organization = organization
    @gh_client = Octokit::Client.new(access_token: gh_token)
  end

  def clonar_entrega!(nombre)
    result = @gh_client.search_repositories "org:#{@organization} #{nombre}\\-", {per_page: 200}
    puts "Encontrados #{result.total_count} repositorios."
    FileUtils.mkdir_p nombre
    Dir.chdir(nombre) do
      result.items.each do |repo|
        if File.exist? repo.name
          puts "Actualizando #{repo.name}..."
          actualizar! repo.name
        else
          puts "Clonando #{repo.name}..."
          clonar! repo.full_name
        end
      end
    end
  end

  def preparar_correccion!(entrega, commit_base)
    entrega.crear_branch! 'base', commit_base
    entrega.crear_branch! 'entrega', 'master'
    TransformacionWollok.transformar!(entrega, self) if TransformacionWollok.aplica?(entrega)
    publicar_cambios! entrega
    crear_pull_request! entrega
  end

  def preparar_entrega!(nombre, repo_base)
    repo = clonar! repo_base
    aplanar_commits! repo
    publicar_repo! nombre, repo
  end

  def nombre
    'Yanapiri Bot'
  end

  def email
    'bot@yanapiri.org'
  end

  def git_author
    "#{nombre} <#{email}>"
  end

  def github_user
    @gh_client.user
  end

  def commit!(repo, mensaje)
    repo.commit_all mensaje, author: git_author
  end

  private

  def aplanar_commits!(repo)
    repo.chdir do
      `git checkout --orphan new-master master`
      commit! repo, 'Enunciado preparado por Yanapiri'
      `git branch -M new-master master`
    end
  end

  def actualizar!(repo_path)
    Git.open(repo_path).pull
  end

  def clonar!(repo_slug)
    Git.clone "git@github.com:#{repo_slug}.git", repo_slug.split('/').last
  end

  def crear_pull_request!(entrega)
    @gh_client.create_pull_request("#{@organization}/#{entrega.id}", "base", "entrega", "Corrección", entrega.mensaje_pull_request) rescue nil
  end

  def publicar_repo!(nombre, repo)
    repo_nuevo = crear_repo!(nombre)
    repo.remote('origin').remove
    repo.add_remote 'origin', repo_nuevo.ssh_url
    repo.push
  end

  def crear_repo!(nombre)
    @gh_client.create_repository nombre, organization: @organization
  end

  def publicar_cambios!(entrega)
    entrega.repo.push 'origin', '--all'
  end
end
