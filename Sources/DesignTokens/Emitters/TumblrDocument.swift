import Foundation

/// The fixed markup of the Tumblr full theme: the document around the generated style block.
///
/// Taken from the owner's working theme (the block already substituted into their markup), with three things taken out: the Google Tag
/// Manager snippets, the blog's wordmark and the links to the owner's own sites. Those are parameters of ``TumblrThemeEmitter``.
/// Only Tumblr's `{...}` tags and the contract's class names appear here, no colour or font literal.
enum TumblrDocument {
    static let doctypeAndHead = #"""
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
"""# + "\n"
    static let titleAndFeeds = #"""
		<title>{Title}{block:PostTitle} - {PostTitle}{/block:PostTitle}</title>
		<link rel="icon" href="{Favicon}"/>
		<link rel="alternate" type="application/rss+xml" title="RSS" href="{RSS}"/>
"""# + "\n"
    static let scriptAndViewport = #"""
		<script>document.documentElement.className += " js";</script>
		<meta name="viewport" content="width=device-width, initial-scale=1"/>
"""# + "\n"
    static let descriptionAndEndOfHead = #"""
		<meta name="description" content="{Description}"/>
</head>
"""# + "\n"
    static let wrapperOpen = #"""
		<div class="wrapper">
			<div class="header">
"""# + "\n"
    static let statusAndDescription = #"""
					<div id="status"><ul></ul></div>
					<p>{Description}</p>
"""# + "\n"
    static let main = #"""
			<div class="main">
				{block:SearchPage}
				<div class="post">
					<div class="datetime">
						{SearchResultCount} result(s)
					</div>
					searched for <em>{SearchQuery}</em>
				</div>
				{/block:SearchPage}
				{block:Posts}
				<div class="post{block:NewDayDate} newday{/block:NewDayDate}">
						<div class="datetime">
							{block:NewDayDate}<span class="day">{DayOfMonth}</span><span class="my">{ShortMonth} {year}</span>{/block:NewDayDate}
							<span class="time">{12Hour}:{Minutes}{AmPm}</span>
							<span class="type">{block:Regular}Text{/block:Regular}{block:Photo}Photo{/block:Photo}{block:Quote}Quote{/block:Quote}{block:Video}Video{/block:Video}{block:Audio}Audio{/block:Audio}{block:Link}Link{/block:Link}{block:Conversation}Chat{/block:Conversation}{block:Photoset}Photos{/block:Photoset}{block:Answer}Ask{/block:Answer}</span>
							{block:Pagination}<span class="row"><span class="k">Notes</span><a href="{Permalink}">{NoteCount}</a></span>{/block:Pagination}
							{block:SearchPage}<span class="row"><span class="k">Notes</span><a href="{Permalink}">{NoteCount}</a></span>{/block:SearchPage}
							{block:PermalinkPage}<span class="row"><span class="k">Index</span><a href="/">Home</a></span>{/block:PermalinkPage}
							{block:RebloggedFrom}<span class="row"><span class="k">Via</span><a href="{ReblogParentURL}">{ReblogRootName}</a></span>{/block:RebloggedFrom}
							{block:ExternalAudio}<span class="row"><span class="k">File</span><a href="{ExternalAudioURL}">Download</a></span>{/block:ExternalAudio}
						</div>
				
				{block:Regular}
					{block:Title}
					    <h2>{Title}</h2>
					{/block:Title}
					<div class="body">{Body}</div>
				{/block:Regular}

				{block:Photo}
					<span class="photo">
					    {LinkOpenTag}
					        <img src="{PhotoURL-500}" srcset="{PhotoURL-500} 500w, {PhotoURL-HighRes} 1280w" sizes="(max-width: 720px) 100vw, 900px" alt="{PhotoAlt}" title="{PhotoAlt}">
					    {LinkCloseTag}
					</span>
					{block:Caption}<div class="caption">{Caption}</div>{/block:Caption}
				{/block:Photo}

				{block:Quote}
					<span class="{Length}_quote">{Quote}</span>
				 <p><i>{Source}</i></p>
				{/block:Quote}

				{block:Video}
					<span class="video">{Video-500}</span>
					{block:Caption}<div class="caption">{Caption}</div>{/block:Caption}
				{/block:Video}

				{block:Audio}
					{block:AlbumArt}
					    <img src="{AlbumArtURL}" alt="" />
					{/block:AlbumArt}
					<p>{AudioPlayerGrey}</p>
					{block:Caption}<div class="caption">{Caption}</div>{/block:Caption}
				<!--{block:Artist}{Artist}{/block:Artist} - {block:TrackName}{TrackName}{/block:TrackName}-->
<!--<div class="navright">{block:ExternalAudio}<a href="{ExternalAudioURL}">download</a>{/block:ExternalAudio}</div>-->
				{/block:Audio}
				
			 
				{block:Link}
					<h2><a href="{URL}" {Target}>{Name}</a></h2>
					{block:Description}<div class="body">{Description}</div>{/block:Description}
				{/block:Link}

				{block:Photoset}
					<div class="photoset-block">
						<div class="carousel"><div class="viewport">{block:Photos}<figure class="slide"><img src="{PhotoURL-500}" srcset="{PhotoURL-500} 500w, {PhotoURL-HighRes} 1280w" sizes="(max-width: 720px) 100vw, 900px" alt="{PhotoAlt}"></figure>{/block:Photos}</div></div>
						<div class="photoset">{Photoset-500}</div>
					</div>
					{block:Caption}<div class="caption">{Caption}</div>{/block:Caption}
				{/block:Photoset}

				{block:Answer}
					<div class="question"><span class="asker">{Asker} asked</span><h2>{Question}</h2></div>
					<div class="body">{Answer}</div>
				{/block:Answer}

				{block:Conversation}
					{block:Title}<h2>{Title}</h2>{/block:Title}
					<p>
					{block:Lines}
					    {block:Label}<strong>
					        {Label}
					    {/block:Label}</strong>
					    {Line}<br />
					{/block:Lines}
					</p>
				{/block:Conversation}
				
				</div>
					{block:ContentSource}
                    <!--{SourceURL}{block:SourceLogo}<img src="{BlackLogoURL}"-->
                    <!--width="{LogoWidth}" height="{LogoHeight}" alt="{SourceTitle}" />  -->
                    <!--{/block:SourceLogo}-->
                    <!--{block:NoSourceLogo}{SourceLink}{/block:NoSourceLogo} -->
                    {/block:ContentSource}
				{/block:Posts}
				<script>
(function () {
	document.querySelectorAll('.npf-link-block .poster .title').forEach(function (t) {
		var p = t.parentNode;
		p.parentNode.insertBefore(t, p.nextSibling);
	});
	document.querySelectorAll('.datetime > .row').forEach(function (r) {
		var k = r.querySelector('.k'), a = r.querySelector('a');
		if (k && a && k.textContent.trim() === 'Notes' && /^\d+$/.test(a.textContent.trim())) {
			a.textContent = Number(a.textContent.trim()).toLocaleString('en-US');
		}
	});
	document.querySelectorAll('.photoset-block').forEach(function (box) {
		var car = box.querySelector('.carousel'), vp = car.querySelector('.viewport');
		var slides = vp.querySelectorAll('.slide'), fallback = box.querySelector('.photoset');
		if (!slides.length) { car.remove(); return; }          /* no pictures came through: keep Tumblr's own box */
		if (fallback) { fallback.remove(); }
		car.setAttribute('role', 'group');
		car.setAttribute('aria-roledescription', 'carousel');
		car.setAttribute('aria-label', 'Photos');
		if (slides.length < 2) { return; }
		var bar = document.createElement('div');
		bar.className = 'bar';
		bar.innerHTML = '<span class="count" aria-live="polite"></span><span class="controls"><button type="button" class="prev" aria-label="Previous photo">&larr; Prev</button><button type="button" class="next" aria-label="Next photo">Next &rarr;</button></span>';
		car.appendChild(bar);
		var count = bar.querySelector('.count'), prev = bar.querySelector('.prev'), next = bar.querySelector('.next'), at = 0;
		vp.setAttribute('tabindex', '0');
		function fit() { vp.style.height = slides[at].getBoundingClientRect().height + 'px'; }
		function update() {
			count.textContent = (at + 1) + ' / ' + slides.length;
			prev.disabled = at === 0;
			next.disabled = at === slides.length - 1;
			fit();
		}
		function go(n) {
			at = Math.max(0, Math.min(slides.length - 1, n));
			vp.scrollTo({ left: at * vp.clientWidth });
			update();
		}
		prev.addEventListener('click', function () { go(at - 1); });
		next.addEventListener('click', function () { go(at + 1); });
		vp.addEventListener('keydown', function (e) {
			if (e.key === 'ArrowLeft') { go(at - 1); e.preventDefault(); }
			if (e.key === 'ArrowRight') { go(at + 1); e.preventDefault(); }
		});
		vp.addEventListener('scroll', function () {
			var n = Math.round(vp.scrollLeft / Math.max(1, vp.clientWidth));
			if (n !== at && n >= 0 && n < slides.length) { at = n; update(); }
		});
		slides.forEach(function (s) { var im = s.querySelector('img'); if (im) { im.addEventListener('load', fit); } });
		window.addEventListener('resize', fit);
		window.addEventListener('load', fit);
		update();
	});
	document.querySelectorAll('.video iframe[width][height]').forEach(function (f) {
		var w = parseFloat(f.getAttribute('width')), h = parseFloat(f.getAttribute('height'));
		if (!(w > 0 && h > 0)) { return; }
		f.style.width = '100%';
		f.style.height = 'auto';
		f.style.aspectRatio = w + ' / ' + h;                      /* the shape the publisher gave it */
		f.style.setProperty('--ar', w + ' / ' + h);
		if (h / w > 1.15) { f.closest('.video').classList.add('portrait'); }   /* a phone-shaped video takes four columns */
		/* Tumblr's player page draws the video at the width in its address (500 by default) and fills the rest of a wider
		   frame with black. It accepts any width, so ask for the width the frame actually has. */
		var m = /^(https?:\/\/(?:www\.)?tumblr\.com\/video\/[^\/]+\/\d+\/)(\d+)\/?$/.exec(f.src);
		if (m) {
			var asked = 0;
			var sizePlayer = function () {
				var target = Math.round(f.parentNode.getBoundingClientRect().width);
				if (target < 200) { return; }
				if (asked && Math.abs(target - asked) / asked < 0.1) { return; }
				asked = target;
				f.src = m[1] + target + '/';
			};
			sizePlayer();
			var timer;
			window.addEventListener('resize', function () { clearTimeout(timer); timer = setTimeout(sizePlayer, 250); });
		}
	});
	document.querySelectorAll('figure[data-orig-width][data-orig-height]').forEach(function (fig) {
		var v = fig.querySelector('video');
		if (!v) { return; }
		var w = parseFloat(fig.getAttribute('data-orig-width')), h = parseFloat(fig.getAttribute('data-orig-height'));
		if (!(w > 0 && h > 0)) { return; }
		v.style.aspectRatio = w + ' / ' + h;                       /* the box has the right shape before the video loads */
		if (h / w > 1.15) { fig.classList.add('portrait'); }       /* a phone-shaped video takes four columns */
	});
	function mark(img) {
		var row = img.closest('.npf_row');
		if (row && row.querySelectorAll('.npf_col').length > 1) { return; }
		if (img.naturalWidth && img.naturalHeight / img.naturalWidth > 1.15) {
			var box = row || img.closest('figure') || img.closest('.photo') || img.parentNode;
			box.classList.add('portrait');
		}
	}
	document.querySelectorAll('.post img').forEach(function (img) {
		if (img.complete) { mark(img); } else { img.addEventListener('load', function () { mark(img); }); }
	});
})();
</script>
		

				{block:PermalinkPage}
				{block:PostNotes}
				<div class="post">
					<h3>Notes</h3>
					<p>{PostNotes}</p>
				</div>
				{/block:PostNotes}
				<div class="post disqus">
	<!--
		insert Disqus comment code here.
	-->
				</div>
				{/block:PermalinkPage}


				{block:Pagination}
				<div class="pager">
{block:NextPage}
				<div class="navleft">
					&larr;&nbsp;<a href="{NextPage}">older</a>
				</div>
				{/block:NextPage}

{block:PreviousPage}
				<div class="navright">
					<a href="{PreviousPage}">newer</a>&nbsp;&rarr;
				</div>
				{/block:PreviousPage}				
								<div class="navcenter">
					<span class="long_quote">{CurrentPage}</span>
				</div>
				</div>
					{/block:Pagination}
				
				{block:PermalinkPagination}
					<div class="pager">
					    {block:NextPost}
				        <div class="navleft">
				        	&larr;&nbsp;<a href="{NextPost}">next post</a>
				        </div>
				    {/block:NextPost}
				    
				    {block:PreviousPost}
			            <div class="navright">
			    	        <a href="{PreviousPost}">previous post</a>&nbsp;&rarr;
			            </div>
			        {/block:PreviousPost}
					</div>
					{/block:PermalinkPagination}
				
"""# + "\n"
    static let tail = #"""
			</div>
		</div>
	</body>
</html>
"""# + "\n"
}
