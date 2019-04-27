class Bot
  def initialize(organization, gh_token)
    @organization = organization
    @gh_client = Octokit::Client.new(access_token: gh_token)
  end

  def clonar_entrega!(nombre)
    result = @gh_client.search_repositories "org:#{@organization} #{nombre} in:name", {per_page: 200}
    puts "Encontrados #{result.total_count} repositorios."
    FileUtils.mkdir_p nombre
    Dir.chdir(nombre) do
      result.items.each do |repo|
        puts "Clonando #{repo.name}..."
        Git.clone repo.ssh_url, repo.name
      end
    end
  end
end
