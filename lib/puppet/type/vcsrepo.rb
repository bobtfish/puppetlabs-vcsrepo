require 'pathname'

Puppet::Type.newtype(:vcsrepo) do
  desc "A local version control repository"

  feature :gzip_compression,
          "The provider supports explicit GZip compression levels"

  feature :bare_repositories,
          "The provider differentiates between bare repositories
          and those with working copies",
          :methods => [:bare_exists?, :working_copy_exists?]

  feature :filesystem_types,
          "The provider supports different filesystem types"

  ensurable do

    newvalue :present do
      provider.create
    end

    newvalue :bare, :required_features => [:bare_repositories] do
      provider.create
    end

    newvalue :absent do
      provider.destroy
    end

    def retrieve
      prov = @resource.provider
      if prov
        if prov.class.feature?(:bare_repositories)
          if prov.working_copy_exists?
            :present
          elsif prov.bare_exists?
            :bare
          else
            :absent
          end
        else
          prov.exists? ? :present : :absent
        end
      else
        raise Puppet::Error, "Could not find provider"
      end
    end

  end

  newparam(:path) do
    desc "Absolute path to repository"
    isnamevar
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise ArgumentError, "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:source) do
    desc "The source URI for the repository"
  end

  newparam(:fstype, :required_features => [:filesystem_types]) do
    desc "Filesystem type"
  end

  newproperty(:revision) do
    desc "The revision of the repository"
    newvalue(/^\S+$/)
  end

  newparam :compression, :required_features => [:gzip_compression] do
    desc "Compression level"
    validate do |amount|
      unless Integer(amount).between?(0, 6)
        raise ArgumentError, "Unsupported compression level: #{amount} (expected 0-6)"
      end
    end
  end

end
