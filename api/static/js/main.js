var container = document.getElementById('container-games')

fetch('api/nes').then(res => res.json()).then(games => {
    for (let game of games) {
        let a = document.createElement('a')
        let div = document.createElement('div')
        let title = document.createElement('h2')
        let image = document.createElement('img')

        div.appendChild(image)
        div.appendChild(title)
        a.appendChild(div)
        container.appendChild(a)

        let url = `/static/img/nes/${game.id}.png`
        a.href = url
        a.title = game.id
        title.innerText = game.name
        image.src = url
    }
})
