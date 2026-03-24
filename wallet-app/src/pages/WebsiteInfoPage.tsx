const infoSections = [
  {
    title: 'About Backpack',
    description: 'Backpack is a next level crypto wallet for Solana and Ethereum users.',
  },
  {
    title: 'Security',
    description: 'Approval flow and request isolation are designed to reduce signing risks.',
  },
  {
    title: 'Support',
    description: 'Use official docs, Discord and release notes to track updates.',
  },
  {
    title: 'Notice',
    description: 'This is a UI replica for pixel alignment and interaction benchmarking.',
  },
]

export function WebsiteInfoPage() {
  return (
    <section className="site-page site-page-info">
      <div className="site-section-head">
        <h2>Information</h2>
      </div>
      <div className="site-info-list">
        {infoSections.map((item) => (
          <article key={item.title} className="site-card site-card-interactive backpack-info-card">
            <h3>{item.title}</h3>
            <p>{item.description}</p>
          </article>
        ))}
      </div>
    </section>
  )
}
