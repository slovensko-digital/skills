# Serves UX explorations from /explorations (development only, see routes).
class ExplorationsController < ActionController::Base
  ROOT = Rails.root.join("explorations")

  skip_forgery_protection

  Exploration = Data.define(:folder, :started_at, :title, :status, :note)

  def index
    @explorations = ROOT.children.select(&:directory?).sort.reverse.map { |dir| read(dir) }
    render inline: LISTING
  end

  def show
    # Only files that exist under explorations/ are served, never a path built from params.
    path = ROOT.glob("**/*").find { |entry| entry.relative_path_from(ROOT).to_s == params[:path] }
    return head :not_found unless path

    if path.directory?
      return redirect_to "#{request.path}/" unless request.original_fullpath.end_with?("/")
      path = path.join("index.html")
      return head :not_found unless path.file?
    end

    response.headers["Cache-Control"] = "no-store"
    send_file path, disposition: :inline, type: Rack::Mime.mime_type(path.extname, "text/plain")
  end

  private

  # "PR #102" in a note links to that pull request on GitHub.
  def linked_note(note)
    repo = `git -C #{Rails.root} remote get-url origin`.strip.sub(/\.git\z/, "").sub(/\Agit@github\.com:/, "https://github.com/")
    ERB::Util.html_escape(note).gsub(/PR #(\d+)/) { %(<a href="#{repo}/pull/#{$1}">#{$&}</a>) }.html_safe
  end
  helper_method :linked_note

  def read(dir)
    html = dir.join("index.html").read if dir.join("index.html").file?
    meta = ->(name) { html.to_s[/<meta name="exploration-#{name}" content="([^"]*)"/, 1] }

    Exploration.new(
      folder: dir.basename.to_s,
      started_at: Time.strptime(dir.basename.to_s[0, 14], "%Y%m%d%H%M%S"),
      title: html.to_s[%r{<title>(.*?)</title>}m, 1] || dir.basename.to_s,
      status: meta.call("status") || "open",
      note: meta.call("note")
    )
  end

  # Structure only: give it the app's own look with the app's classes.
  LISTING = <<~ERB
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>Explorations</title>
      <%= stylesheet_link_tag "application" %>
    </head>
    <body>
      <h1>Explorations</h1>
      <ul>
        <% @explorations.each do |e| %>
          <li>
            <a href="/explorations/<%= e.folder %>/"><span class="time"><%= e.started_at.strftime("%Y-%m-%d %H:%M") %></span><span class="title"><%= e.title %></span></a>
            <span class="meta"><% if e.note.present? %><span class="note"><%= linked_note(e.note) %></span><% end %><span class="status <%= e.status %>"><%= e.status %></span></span>
          </li>
        <% end %>
      </ul>
      <% if @explorations.empty? %><p>No explorations yet.</p><% end %>
    </body>
    </html>
  ERB
end
