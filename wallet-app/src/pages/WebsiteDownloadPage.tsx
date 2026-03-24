const downloadChannels = [
  {
    platform: 'Chrome',
    packageName: 'Chrome Web Store',
    version: 'Latest',
    note: 'Install Backpack extension from Chrome Web Store.',
  },
  {
    platform: 'Brave',
    packageName: 'Brave Browser',
    version: 'Latest',
    note: 'Use the same extension package with Brave support.',
  },
  {
    platform: 'Arc',
    packageName: 'Arc Browser',
    version: 'Latest',
    note: 'Install via Chrome extension compatibility mode.',
  },
]

export function WebsiteDownloadPage() {
  return (
    <section className="site-page site-page-download">
      <div className="site-section-head">
        <h2>Download</h2>
      </div>
      <div className="site-download-grid">
        {downloadChannels.map((item) => (
          <article key={item.platform} className="site-card site-card-interactive backpack-download-card">
            <p className="site-card-label">{item.platform}</p>
            <h3>{item.packageName}</h3>
            <p>{item.note}</p>
            <div className="site-download-actions">
              <button type="button">Download {item.version}</button>
            </div>
          </article>
        ))}
      </div>
    </section>
  )
}
