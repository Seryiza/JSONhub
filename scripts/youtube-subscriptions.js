/*
  Instructions:
  1. Open URL: https://www.youtube.com/feed/channels
  2. Paste this script into the DevTools Console and run it
  3. Wait until the promise resolves with the subscriptions array

  Notes:
  - The script uses a simple, but working technique: "scroll -> spinner? -> scroll again" loop
*/

/**
 * Scroll the subscriptions page to the end, collect all rendered channels,
 * and return the result as plain data.
 * @returns {Promise<Array<{
 *   name: string | undefined,
 *   link: string | undefined,
 *   description: string | undefined,
 *   subscribersInfo: string | undefined,
 *   avatarLink: string | undefined
 * }>>}
 */
async function getYoutubeSubscriptions() {
  await scrollUntilPageStopsGrowing();
  return getAllSubscriptionChannelElements().map(parseChannelElement);
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
    name: getChannelName(el),
    link: getChannelLink(el),
    description: getChannelDescription(el),
    avatarLink: getChannelAvatarLink(el),
    subscribersInfo: getChannelSubscribersInfo(el),
  }
}

/**
 * Get the Polymer-backed channel renderer data if YouTube exposed it on the element.
 * @param {Element & {
 *   data?: unknown,
 *   polymerController?: { data?: unknown }
 * }} el
 */
function getChannelRendererData(el) {
  return el.data ?? el.polymerController?.data;
}

/**
 * @param {Element} el
 * @returns {string | undefined}
 */
function getChannelName(el) {
  const data = getChannelRendererData(el);
  return parseText(data?.title) ?? getElementText(el, 'yt-formatted-string.ytd-channel-name');
}

/**
 * @param {Element} el
 * @returns {string | undefined}
 */
function getChannelLink(el) {
  const data = getChannelRendererData(el);
  return toAbsoluteUrl(data?.navigationEndpoint?.commandMetadata?.webCommandMetadata?.url)
    ?? el.querySelector('a.channel-link')?.href;
}

/**
 * @param {Element} el
 * @returns {string | undefined}
 */
function getChannelDescription(el) {
  const data = getChannelRendererData(el);
  return parseText(data?.descriptionSnippet) ?? getElementText(el, '#description');
}

/**
 * @param {Element} el
 * @returns {string | undefined}
 */
function getChannelAvatarLink(el) {
  const data = getChannelRendererData(el);
  return getLargestThumbnailUrl(data?.thumbnail?.thumbnails)
    ?? getAvatarLinkFromDom(el);
}

/**
 * @param {Element} el
 * @returns {string | undefined}
 */
function getChannelSubscribersInfo(el) {
  const data = getChannelRendererData(el);
  return getElementText(el, '#video-count') ?? parseText(data?.videoCountText);
}

/**
 * @param {Element} el
 * @param {string} selector
 * @returns {string | undefined}
 */
function getElementText(el, selector) {
  return el.querySelector(selector)?.textContent?.trim();
}

/**
 * Convert YouTube text objects to plain text.
 * @param {unknown} value
 * @returns {string | undefined}
 */
function parseText(value) {
  if (typeof value === 'string') return value.trim();
  if (!value || typeof value !== 'object') return undefined;
  if (typeof value.simpleText === 'string') return value.simpleText.trim();
  if (Array.isArray(value.runs)) {
    return value.runs
      .map(run => run?.text ?? '')
      .join('')
      .trim();
  }
}

/**
 * Pick the largest thumbnail URL from a YouTube thumbnails list.
 * @param {Array<{url?: string}> | undefined} thumbnails
 * @returns {string | undefined}
 */
function getLargestThumbnailUrl(thumbnails) {
  const url = thumbnails
    ?.map(thumb => thumb?.url?.trim())
    .filter(Boolean)
    .at(-1);
  return toAbsoluteUrl(url);
}

/**
 * Resolve a relative or protocol-relative URL against the current page origin.
 * @param {string | undefined} url
 * @returns {string | undefined}
 */
function toAbsoluteUrl(url) {
  if (!url) return undefined;
  return new URL(url, location.origin).href;
}

/**
 * Fall back to the rendered avatar image when renderer data is unavailable.
 * @param {Element} el
 * @returns {string | undefined}
 */
function getAvatarLinkFromDom(el) {
  const img = el.querySelector('#avatar img');
  const srcset = img?.currentSrc
    || img?.src
    || img?.getAttribute('src')
    || img?.getAttribute('data-src')
    || img?.getAttribute('data-thumb')
    || img?.getAttribute('srcset');
  if (!srcset) return undefined;
  const url = srcset
    .split(',')
    .map(part => part.trim().split(/\s+/)[0])
    .filter(Boolean)
    .at(-1);
  return toAbsoluteUrl(url);
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

JSON.stringify(await getYoutubeSubscriptions())
