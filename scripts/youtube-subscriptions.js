/*
  Instructions:
  1. Open URL: https://www.youtube.com/feed/channels
  2. Paste this script into the DevTools Console and run it
  3. Wait until the script logs formatted JSON text
  4. Copy the JSON text from the Console output

  Notes:
  - The script uses a simple, but working technique: "scroll -> spinner? -> scroll again" loop
*/

/**
 * Scroll the subscriptions page to the end, collect all rendered channels,
 * and log the result as formatted JSON text.
 * @returns {Promise<void>}
 */
async function logYoutubeSubscriptionsAsJson() {
  await scrollUntilPageStopsGrowing();
  const channels = getAllSubscriptionChannelElements().map(parseChannelElement);
  console.log(JSON.stringify(channels, null, 2));
}

// === Helper Functions ===

/**
 * Parse a rendered YouTube subscription channel item into a plain object.
 * @param {Element} el
 * @returns {{
 *   name: string | undefined,
 *   link: string | undefined,
 *   description: string | undefined,
 *   subscribersInfo: string | undefined,
 *   avatarLink: string | undefined
 * }}
 */
function parseChannelElement(el) {
  return {
    name: el.querySelector('yt-formatted-string.ytd-channel-name')?.textContent.trim(),
    link: el.querySelector('a.channel-link')?.href,
    description: el.querySelector('#description')?.textContent.trim(),
    avatarLink: el.querySelector('#avatar img')?.src,

    // On /feed/channels, YouTube currently renders the formatted subscriber count in #video-count.
    subscribersInfo: el.querySelector('#video-count')?.textContent.trim(),
  }
}

/**
 * Get all currently rendered subscription channel elements from the page.
 * @returns {Element[]}
 */
function getAllSubscriptionChannelElements() {
  return Array.from(
    document.querySelectorAll('ytd-channel-renderer')
  );
}

/**
 * Check whether the page still shows an active loading spinner.
 * @returns {boolean}
 */
function hasActiveLoadingSpinner() {
  return Boolean(document.querySelector('tp-yt-paper-spinner[active]'));
}

/**
 * Keep scrolling until the page height stops growing, the viewport is at the
 * bottom, and YouTube is no longer loading more items.
 * @returns {Promise<{reason: 'done', height: number}>}
 */
async function scrollUntilPageStopsGrowing() {
  const page = document.documentElement;

  while (true) {
    const previousHeight = page.scrollHeight;
    window.scrollTo(0, previousHeight);

    await new Promise(r => setTimeout(r, 500));

    const currentHeight = page.scrollHeight;
    const isAtBottom = Math.abs(page.scrollHeight - page.clientHeight - page.scrollTop) <= 2;
    const isLoading = hasActiveLoadingSpinner();

    if (currentHeight === previousHeight && isAtBottom && !isLoading) {
      return { reason: 'done', height: currentHeight };
    }
  }
}

await logYoutubeSubscriptionsAsJson();
