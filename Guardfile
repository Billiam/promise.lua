group :spec do
  guard :shell do
    watch %r(^spec/*_spec\.lua$) do |m|
      `busted #{m}`
    end

    watch %r(^*.lua$) do |m|
      `busted`
    end
  end
end