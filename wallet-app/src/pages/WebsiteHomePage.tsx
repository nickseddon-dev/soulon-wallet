const highlights = [
  {
    title: 'CoinDesk',
    description: 'Heavy Demand for Madlads NFT Breaks Internet, Delays Mint',
    image:
      'https://www.coindesk.com/resizer/aHFTwpGDGmuTTf1AC6ueAsmJv1w=/2112x1188/filters:quality(80):format(webp)/cloudfront-us-east-1.images.arcpublishing.com/coindesk/FB4VEP3MIBCLNHHOHFWHRHCP2A.jpg',
    href: 'https://www.coindesk.com/web3/2023/04/21/heavy-demand-for-madlads-nft-breaks-internet-delays-mint',
  },
  {
    title: 'Fortune Crypto',
    description: 'Solana has outperformed Bitcoin and Ethereum since January thanks in part to Mad Lads NFTs',
    image: 'https://content.fortune.com/wp-content/uploads/2023/04/Coins-Solana-6.jpg?w=1440&q=75',
    href: 'https://fortune.com/crypto/2023/04/28/solana-cryptocurrency-outperforms-bitcoin-and-ethereum-ytd-mad-lads/',
  },
  {
    title: 'Decrypt',
    description: 'Solana NFTs Come to Portfolio App Floor Amid Mad Lads Boom',
    image:
      'https://img.decrypt.co/insecure/rs:fit:1536:0:0:0/plain/https://cdn.decrypt.co/wp-content/uploads/2023/01/floor-app-2023-gID_7.png@webp',
    href: 'https://decrypt.co/137634/solana-nfts-come-to-portfolio-app-floor-amid-mad-lads-boom',
  },
  {
    title: 'Blockworks',
    description: 'So You Know What NFTs Are, but How About xNFTs?',
    image:
      'https://blockworks.co/_next/image?url=https%3A%2F%2Fblockworks-co.imgix.net%2Fwp-content%2Fuploads%2F2023%2F05%2FNFT-royalties.jpg&w=1920&q=75',
    href: 'https://blockworks.co/news/you-know-xnfts',
  },
]

export function WebsiteHomePage() {
  return (
    <section className="site-page site-page-home backpack-home-page">
      <div className="site-section-head">
        <h2>News</h2>
      </div>
      <div className="site-news-grid">
        {highlights.map((item) => (
          <article key={item.title} className="site-card site-card-interactive backpack-news-card">
            <div className="backpack-news-body">
              <h3>{item.title}</h3>
              <p>{item.description}</p>
              <a href={item.href} target="_blank" rel="noopener noreferrer">
                Read →
              </a>
            </div>
            <img src={item.image} alt={item.title} />
          </article>
        ))}
      </div>
    </section>
  )
}
